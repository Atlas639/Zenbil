//
//  PreviewContainer.swift
//  Zenbil
//
//  Created by Berhan Witte on 10.07.24.
//

import SwiftUI

typealias AspectRatio = CGSize
let photoAspectRatio = AspectRatio(width: 3.0, height: 4.0)
let movieAspectRatio = AspectRatio(width: 9.0, height: 16.0)

@MainActor
struct PreviewContainer<Content: View, CameraModel: Camera>: View {
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State var camera: CameraModel
    @State private var blurRadius = CGFloat.zero
    
    private let photoModeOffset = CGFloat(-44)
    private let content: Content
    
    init(camera: CameraModel, @ViewBuilder content: () -> Content) {
        self.camera = camera
        self.content = content()
    }
    
    var body: some View {
        if horizontalSizeClass == .compact {
            ZStack {
                previewView
            }
            .clipped()
            .aspectRatio(aspectRatio, contentMode: .fit)
            .offset(y: photoModeOffset)
        } else {
            previewView
        }
    }
    
    var previewView: some View {
        content
            .blur(radius: blurRadius, opaque: true)
    }
    
    func updateBlurRadius(_: Bool, _ isSwitching: Bool) {
        withAnimation {
            blurRadius = isSwitching ? 30 : 0
        }
    }
    
    var aspectRatio: AspectRatio {
        return photoAspectRatio
    }
}
