//
//  CameraView.swift
//  Zenbil
//
//  Created by Berhan Witte on 10.07.24.
//

import SwiftUI
import AVFoundation

@MainActor
struct CameraView<CameraModel: Camera>: PlatformView {
    
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    @State var camera: CameraModel
    
    @State var swipeDirection = SwipeDirection.left
    
    var body: some View {
        PreviewContainer(camera: camera) {
            CameraPreview(source: camera.previewSource)
                .onTapGesture { location in
                    Task { await camera.focusAndExpose(at: location) }
                }
                .simultaneousGesture(swipeGesture)
                .opacity(camera.shouldFlashScreen ? 0 : 1)
        }
    }

    var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 50)
            .onEnded {
                swipeDirection = $0.translation.width < 0 ? .left : .right
            }
    }
}

#Preview {
    CameraView(camera: PreviewCameraModel())
}

enum SwipeDirection {
    case left
    case right
    case up
    case down
}
