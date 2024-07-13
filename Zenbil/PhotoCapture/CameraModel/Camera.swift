//
//  Camera.swift
//  Zenbil
//
//  Created by Berhan Witte on 10.07.24.
//

import SwiftUI

@MainActor
protocol Camera: AnyObject {
    var status: CameraStatus { get }
    var captureActivity: CaptureActivity { get }
    var previewSource: PreviewSource { get }
    var thumbnails: [UUID: CGImage] { get }
    
    func start() async
    var isSwitchingModes: Bool { get }
    var photoFeatures: PhotoFeatures { get }
    func focusAndExpose(at point: CGPoint) async
    func capturePhoto() async
    var shouldFlashScreen: Bool { get }
    var error: Error? { get }
}
