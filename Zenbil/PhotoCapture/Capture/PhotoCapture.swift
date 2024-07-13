//
//  PhotoCapture.swift
//  Zenbil
//
//  Created by Berhan Witte on 10.07.24.
//

import AVFoundation
import CoreImage

enum PhotoCaptureError: Error {
    case noPhotoData
}

final class PhotoCapture: OutputService {
    
    @Published private(set) var captureActivity: CaptureActivity = .idle
    let output = AVCapturePhotoOutput()
    private var photoOutput: AVCapturePhotoOutput { output }
    private(set) var capabilities: CaptureCapabilities = .unknown
    
    func capturePhoto(with features: EnabledPhotoFeatures) async throws -> Photo {
        try await withCheckedThrowingContinuation { continuation in
            let photoSettings = createPhotoSettings(with: features)
            
            let maxQualityPrioritization = photoOutput.maxPhotoQualityPrioritization
            if photoSettings.photoQualityPrioritization.rawValue > maxQualityPrioritization.rawValue {
                photoSettings.photoQualityPrioritization = maxQualityPrioritization
            }
            
            let delegate = PhotoCaptureDelegate(continuation: continuation)
            monitorProgress(of: delegate)
            photoOutput.capturePhoto(with: photoSettings, delegate: delegate)
        }
    }
    
    private func createPhotoSettings(with features: EnabledPhotoFeatures) -> AVCapturePhotoSettings {
        var photoSettings = AVCapturePhotoSettings()
        
        if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
            photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
        }
        
        if let previewPhotoPixelFormatType = photoSettings.availablePreviewPhotoPixelFormatTypes.first {
            photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPhotoPixelFormatType]
        }
        
        photoSettings.maxPhotoDimensions = photoOutput.maxPhotoDimensions
        photoSettings.flashMode = features.isFlashEnabled ? .auto : .off
        
        if let prioritization = AVCapturePhotoOutput.QualityPrioritization(rawValue: features.qualityPrioritization.rawValue) {
            photoSettings.photoQualityPrioritization = prioritization
        }
        
        return photoSettings
    }
    
    private func monitorProgress(of delegate: PhotoCaptureDelegate) {
        Task {
            for await activity in delegate.activityStream {
                captureActivity = activity
            }
        }
    }
    
    func updateConfiguration(for device: AVCaptureDevice) {
        photoOutput.maxPhotoDimensions = device.activeFormat.supportedMaxPhotoDimensions.last ??
            CMVideoDimensions(width: 0, height: 0)
        updateCapabilities(for: device)
    }
    
    private func updateCapabilities(for device: AVCaptureDevice) {
        capabilities = CaptureCapabilities(isFlashSupported: device.isFlashAvailable,
                                           isLivePhotoCaptureSupported: photoOutput.isLivePhotoCaptureSupported)
    }
}

typealias PhotoContinuation = CheckedContinuation<Photo, Error>

private class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    
    private let continuation: PhotoContinuation
    private var photoData: Data?
    let activityStream: AsyncStream<CaptureActivity>
    private let activityContinuation: AsyncStream<CaptureActivity>.Continuation
    
    init(continuation: PhotoContinuation) {
        self.continuation = continuation
        
        let (activityStream, activityContinuation) = AsyncStream.makeStream(of: CaptureActivity.self)
        self.activityStream = activityStream
        self.activityContinuation = activityContinuation
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        activityContinuation.yield(.photoCapture(willCapture: true))
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            logger.debug("Error capturing photo: \(String(describing: error))")
            return
        }
        photoData = photo.fileDataRepresentation()
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {

        defer {
            activityContinuation.finish()
        }

        if let error {
            continuation.resume(throwing: error)
            return
        }
        
        guard let photoData else {
            continuation.resume(throwing: PhotoCaptureError.noPhotoData)
            return
        }
        
        let photo = Photo(data: photoData, isProxy: false, livePhotoMovieURL: nil)
        continuation.resume(returning: photo)
    }
}

