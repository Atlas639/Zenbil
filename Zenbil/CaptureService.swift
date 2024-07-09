//
//  CaptureService.swift
//  Zenbil
//
//  Created by Berhan Witte on 09.07.24.
//

import Foundation
import AVFoundation

actor CaptureService {
    private let captureSession = AVCaptureSession()
    private var photoOutput: AVCapturePhotoOutput?
    
    func startSession() {
        captureSession.startRunning()
    }
    
    func stopSession() {
        captureSession.stopRunning()
    }
    
    func setupCaptureSession() throws {
        captureSession.beginConfiguration()
        let videoDevice = AVCaptureDevice.default(for: .video)
        let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice!)
        
        guard captureSession.canAddInput(videoDeviceInput) else {
            throw NSError(domain: "Cannot add video input", code: -1, userInfo: nil)
        }
        captureSession.addInput(videoDeviceInput)
        
        photoOutput = AVCapturePhotoOutput()
        guard let photoOutput = photoOutput, captureSession.canAddOutput(photoOutput) else {
            throw NSError(domain: "Cannot add photo output", code: -1, userInfo: nil)
        }
        captureSession.addOutput(photoOutput)
        captureSession.commitConfiguration()
    }
    
    func capturePhoto(delegate: AVCapturePhotoCaptureDelegate) {
        let settings = AVCapturePhotoSettings()
        photoOutput?.capturePhoto(with: settings, delegate: delegate)
    }
}
