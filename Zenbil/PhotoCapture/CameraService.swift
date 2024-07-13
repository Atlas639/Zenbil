
//
//  CameraService.swift
//  Zenbil
//
//  Created by Berhan Witte on 10.07.24.
//

import Foundation
import AVFoundation
import Combine

actor CaptureService {
    
    @Published private(set) var captureActivity: CaptureActivity = .idle
    @Published private(set) var captureCapabilities = CaptureCapabilities.unknown
    @Published private(set) var isInterrupted = false
    
    nonisolated let previewSource: PreviewSource
    
    private let captureSession = AVCaptureSession()
    private let photoCapture = PhotoCapture()
    
    private var outputServices: [any OutputService] { [photoCapture] }
    
    private var activeVideoInput: AVCaptureDeviceInput?
    private let deviceLookup = DeviceLookup()
    private var isSetUp = false
    
    init() {
        previewSource = DefaultPreviewSource(session: captureSession)
        print("CaptureService initialized")
    }
    
    var isAuthorized: Bool {
        get async {
            print("Checking authorization status")
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            var isAuthorized = status == .authorized
            if status == .notDetermined {
                print("Authorization not determined, requesting access")
                isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
            }
            print("Authorization status: \(isAuthorized ? "Authorized" : "Not Authorized")")
            return isAuthorized
        }
    }
    
    func start() async throws {
        print("Starting capture session")
        guard await isAuthorized, !captureSession.isRunning else { return }
        try setUpSession()
        captureSession.startRunning()
        print("Capture session started")
    }
    
    private func setUpSession() throws {
        print("Setting up capture session")
        guard !isSetUp else { return }

        observeOutputServices()
        observeNotifications()
        
        do {
            let defaultCamera = try deviceLookup.defaultCamera
            let defaultMic = try deviceLookup.defaultMic

            activeVideoInput = try addInput(for: defaultCamera)
            try addInput(for: defaultMic)

            captureSession.sessionPreset = .photo
            try addOutput(photoCapture.output)
            
            observeSubjectAreaChanges(of: defaultCamera)
            updateCaptureCapabilities()
            
            isSetUp = true
            print("Capture session setup complete")
        } catch {
            print("Failed to set up capture session: \(error)")
            throw CameraError.setupFailed
        }
    }

    @discardableResult
    private func addInput(for device: AVCaptureDevice) throws -> AVCaptureDeviceInput {
        print("Adding input for device: \(device.localizedName)")
        let input = try AVCaptureDeviceInput(device: device)
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        } else {
            print("Failed to add input for device: \(device.localizedName)")
            throw CameraError.addInputFailed
        }
        
        // Ensure we only set depth data format if available
        if let activeFormat = device.activeDepthDataFormat {
            do {
                try device.lockForConfiguration()
                device.activeDepthDataMinFrameDuration = CMTimeMake(value: 1, timescale: 30)
                device.unlockForConfiguration()
            } catch {
                print("Failed to configure depth data: \(error)")
            }
        } else {
            print("No active depth data format available for device: \(device.localizedName)")
        }
        
        return input
    }
    
    private func addOutput(_ output: AVCaptureOutput) throws {
        print("Adding output: \(output)")
        if captureSession.canAddOutput(output) {
            captureSession.addOutput(output)
        } else {
            print("Failed to add output: \(output)")
            throw CameraError.addOutputFailed
        }
    }
    
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        guard let previewLayer = captureSession.connections.compactMap({ $0.videoPreviewLayer }).first else {
            fatalError("The app is misconfigured. The capture session should have a connection to a preview layer.")
        }
        return previewLayer
    }
    
    func focusAndExpose(at point: CGPoint) {
        print("Focusing and exposing at point: \(point)")
        let devicePoint = videoPreviewLayer.captureDevicePointConverted(fromLayerPoint: point)
        do {
            try focusAndExpose(at: devicePoint, isUserInitiated: true)
        } catch {
            print("Unable to perform focus and exposure operation. \(error)")
        }
    }
    
    private func observeSubjectAreaChanges(of device: AVCaptureDevice) {
        print("Observing subject area changes for device: \(device.localizedName)")
        subjectAreaChangeTask?.cancel()
        subjectAreaChangeTask = Task {
            for await _ in NotificationCenter.default.notifications(named: AVCaptureDevice.subjectAreaDidChangeNotification, object: device).compactMap({ _ in true }) {
                try? focusAndExpose(at: CGPoint(x: 0.5, y: 0.5), isUserInitiated: false)
            }
        }
    }
    private var subjectAreaChangeTask: Task<Void, Never>?
    
    private var currentDevice: AVCaptureDevice {
        guard let device = activeVideoInput?.device else {
            fatalError("No device found for current video input.")
        }
        return device
    }
    
    private func focusAndExpose(at devicePoint: CGPoint, isUserInitiated: Bool) throws {
        let device = currentDevice
        print("Focusing and exposing at device point: \(devicePoint) on device: \(device.localizedName)")
        
        try device.lockForConfiguration()
        
        let focusMode = isUserInitiated ? AVCaptureDevice.FocusMode.autoFocus : .continuousAutoFocus
        if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(focusMode) {
            device.focusPointOfInterest = devicePoint
            device.focusMode = focusMode
        }
        
        let exposureMode = isUserInitiated ? AVCaptureDevice.ExposureMode.autoExpose : .continuousAutoExposure
        if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(exposureMode) {
            device.exposurePointOfInterest = devicePoint
            device.exposureMode = exposureMode
        }
        device.isSubjectAreaChangeMonitoringEnabled = isUserInitiated
        device.unlockForConfiguration()
    }
    
    func capturePhoto(with features: EnabledPhotoFeatures) async throws -> Photo {
        print("Capturing photo with features: \(features)")
        return try await photoCapture.capturePhoto(with: features)
    }
    
    private func updateCaptureCapabilities() {
        print("Updating capture capabilities")
        outputServices.forEach { $0.updateConfiguration(for: currentDevice) }
        captureCapabilities = photoCapture.capabilities
    }
    
    private func observeOutputServices() {
        print("Observing output services")
        photoCapture.$captureActivity.assign(to: &$captureActivity)
    }
    
    nonisolated private func observeNotifications() {
        print("Observing notifications")
        
        NotificationCenter.default.addObserver(forName: AVCaptureSession.wasInterruptedNotification, object: nil, queue: .main) { [weak self] notification in
            guard let self = self, let reason = notification.userInfo?[AVCaptureSessionInterruptionReasonKey] as? Int,
                  let interruptionReason = AVCaptureSession.InterruptionReason(rawValue: reason) else { return }
            Task {
                await self.handleInterruption(reason: interruptionReason)
            }
        }
        
        NotificationCenter.default.addObserver(forName: AVCaptureSession.interruptionEndedNotification, object: nil, queue: .main) { [weak self] _ in
            guard let self = self else { return }
            Task {
                await self.handleInterruptionEnd()
            }
        }
        
        NotificationCenter.default.addObserver(forName: AVCaptureSession.runtimeErrorNotification, object: nil, queue: .main) { [weak self] notification in
            guard let self = self, let error = notification.userInfo?[AVCaptureSessionErrorKey] as? AVError else { return }
            Task {
                await self.handleRuntimeError(error: error)
            }
        }
    }
    
    private func handleInterruption(reason: AVCaptureSession.InterruptionReason) {
        print("Capture session was interrupted: \(reason)")
        isInterrupted = [.audioDeviceInUseByAnotherClient, .videoDeviceInUseByAnotherClient].contains(reason)
    }
    
    private func handleInterruptionEnd() {
        print("Capture session interruption ended")
        isInterrupted = false
    }
    
    private func handleRuntimeError(error: AVError) {
        print("Capture session runtime error: \(error)")
        if error.code == .mediaServicesWereReset {
            if !captureSession.isRunning {
                captureSession.startRunning()
            }
        }
    }
}
