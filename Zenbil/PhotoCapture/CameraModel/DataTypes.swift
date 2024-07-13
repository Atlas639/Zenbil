//
//  DataTypes.swift
//  Zenbil
//
//  Created by Berhan Witte on 10.07.24.
//

import AVFoundation

enum CameraStatus {
    case unknown
    case unauthorized
    case failed
    case running
    case interrupted
}

enum CaptureActivity {
    case idle
    case photoCapture(willCapture: Bool = false)

    var willCapture: Bool {
        if case .photoCapture(let willCapture) = self {
            return willCapture
        }
        return false
    }
}

enum CaptureMode: String, Identifiable, CaseIterable {
    var id: Self { self }
    case photo
    case video
    
    var systemName: String {
        switch self {
        case .photo:
            "camera.fill"
        case .video:
            "video.fill"
        }
    }
}

struct Photo: Sendable {
    let data: Data
    let isProxy: Bool
    let livePhotoMovieURL: URL?
}

struct Movie: Sendable {
    let url: URL
}

@Observable
class PhotoFeatures {
    var isFlashEnabled = false
    var isLivePhotoEnabled = false
    var qualityPrioritization: QualityPrioritization = .quality
    
    var current: EnabledPhotoFeatures {
        .init(isFlashEnabled: isFlashEnabled,
              isLivePhotoEnabled: isLivePhotoEnabled,
              qualityPrioritization: qualityPrioritization)
    }
}

struct EnabledPhotoFeatures {
    let isFlashEnabled: Bool
    let isLivePhotoEnabled: Bool
    let qualityPrioritization: QualityPrioritization
}

struct CaptureCapabilities {
    let isFlashSupported: Bool
    let isLivePhotoCaptureSupported: Bool
    let isHDRSupported: Bool
    
    init(isFlashSupported: Bool = false,
         isLivePhotoCaptureSupported: Bool = false,
         isHDRSupported: Bool = false) {
        
        self.isFlashSupported = isFlashSupported
        self.isLivePhotoCaptureSupported = isLivePhotoCaptureSupported
        self.isHDRSupported = isHDRSupported
    }
    
    static let unknown = CaptureCapabilities()
}

enum QualityPrioritization: Int, Identifiable, CaseIterable, CustomStringConvertible {
    var id: Self { self }
    case speed = 1
    case balanced
    case quality
    var description: String {
        switch self {
        case.speed:
            return "Speed"
        case .balanced:
            return "Balanced"
        case .quality:
            return "Quality"
        }
    }
}

enum CameraError: Error {
    case videoDeviceUnavailable
    case audioDeviceUnavailable
    case addInputFailed
    case addOutputFailed
    case setupFailed
    case deviceChangeFailed
}

protocol OutputService {
    associatedtype Output: AVCaptureOutput
    var output: Output { get }
    var captureActivity: CaptureActivity { get }
    var capabilities: CaptureCapabilities { get }
    func updateConfiguration(for device: AVCaptureDevice)
    func setVideoRotationAngle(_ angle: CGFloat)
}

extension OutputService {
    func setVideoRotationAngle(_ angle: CGFloat) {
        output.connection(with: .video)?.videoRotationAngle = angle
    }
    func updateConfiguration(for device: AVCaptureDevice) {}
}
