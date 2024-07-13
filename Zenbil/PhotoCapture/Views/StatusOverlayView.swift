//
//  StatusOverlayView.swift
//  Zenbil
//
//  Created by Berhan Witte on 10.07.24.
//

import SwiftUI

struct StatusOverlayView: View {
    
    let status: CameraStatus
    let handled: [CameraStatus] = [.unauthorized, .failed, .interrupted]
    
    var body: some View {
        if handled.contains(status) {
            
            Rectangle()
                .fill(Color(white: 0.0, opacity: 0.5))
            
            Text(message)
                .font(.headline)
                .foregroundColor(color == .yellow ? .init(white: 0.25) : .white)
                .padding()
                .background(color)
                .cornerRadius(8.0)
                .frame(maxWidth: 600)
        }
    }
    
    var color: Color {
        switch status {
        case .unauthorized:
            return .red
        case .failed:
            return .orange
        case .interrupted:
            return .yellow
        default:
            return .clear
        }
    }
    
    var message: String {
        switch status {
        case .unauthorized:
            return "You haven't authorized AVCam to use the camera or microphone. Change these settings in Settings -> Privacy & Security"
        case .interrupted:
            return "The camera was interrupted by higher-priority media processing."
        case .failed:
            return "The camera failed to start. Please try relaunching the app."
        default:
            return ""
        }
    }
}

#Preview("Interrupted") {
    CameraView(camera: PreviewCameraModel(status: .interrupted))
}

#Preview("Failed") {
    CameraView(camera: PreviewCameraModel(status: .failed))
}

#Preview("Unauthorized") {
    CameraView(camera: PreviewCameraModel(status: .unauthorized))
}
