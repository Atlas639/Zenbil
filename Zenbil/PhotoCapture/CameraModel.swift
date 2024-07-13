//
//  CameraModel.swift
//  Zenbil
//
//  Created by Berhan Witte on 10.07.24.
//

import Foundation
import SwiftUI
import Combine

@Observable
final class CameraModel: Camera {
    private(set) var status = CameraStatus.unknown
    private(set) var captureActivity = CaptureActivity.idle
    private(set) var photoFeatures = PhotoFeatures()
    private(set) var isSwitchingModes = false
    private(set) var shouldFlashScreen = false
    private(set) var error: Error?
    
    var previewSource: PreviewSource { captureService.previewSource }
    
    private let captureService = CaptureService()
    private let photoHandler = PhotoHandler()
    
    var sessions: [SessionData] = []
    var activeSession: UUID?
    var activeItem: UUID?
    var thumbnails: [UUID: CGImage] = [:]
    
    init() {
        observeThumbnails()
    }
    
    func start() async {
        guard await captureService.isAuthorized else {
            status = .unauthorized
            return
        }
        do {
            try await captureService.start()
            observeState()
            status = .running
        } catch {
            print("Failed to start capture service. \(error)")
            status = .failed
        }
    }
    
    func capturePhoto() async {
        do {
            let photo = try await captureService.capturePhoto(with: photoFeatures.current)
            print("Photo captured successfully")
            await savePhotoToSession(photo)
        } catch {
            self.error = error
            print("Error capturing photo: \(error)")
        }
    }
    
    private func savePhotoToSession(_ photo: Photo) async {
        print("Saving photo to session")
        guard let activeSession = activeSession, let activeItem = activeItem else {
            print("No active session or item found")
            return
        }
        
        guard let sessionIndex = sessions.firstIndex(where: { $0.id == activeSession }),
              let itemIndex = sessions[sessionIndex].items.firstIndex(where: { $0.id == activeItem }) else {
            print("No matching session or item index found")
            return
        }
        
        var session = sessions[sessionIndex]
        var item = session.items[itemIndex]
        
        do {
            print("Calling photoHandler.save")
            try await photoHandler.save(photo: photo, to: &session, in: &item)
            
            updateSession(session, itemIndex: itemIndex, item: item)
        } catch {
            print("Failed to save photo: \(error)")
        }
    }
    
    @MainActor
    private func updateSession(_ session: SessionData, itemIndex: Int, item: ItemData) {
        print("Updating session with new item data")
        
        if let sessionIndex = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[sessionIndex] = session
            print("Session updated at index: \(sessionIndex)")

            sessions[sessionIndex].items[itemIndex] = item
            print("Item updated at index: \(itemIndex) in session \(session.id)")
        } else {
            print("Session not found for ID: \(session.id)")
        }
    }

    private func observeThumbnails() {
        Task {
            for await thumbnail in photoHandler.thumbnails {
                if let activeSession = activeSession, let activeItem = activeItem {
                    thumbnails[activeItem] = thumbnail
                    print("Thumbnail updated for item: \(activeItem) in session: \(activeSession)")
                }
            }
        }
    }
    
    func focusAndExpose(at point: CGPoint) async {
        await captureService.focusAndExpose(at: point)
    }
    
    private func flashScreen() {
        shouldFlashScreen = true
        withAnimation(.linear(duration: 0.01)) {
            shouldFlashScreen = false
        }
    }
    
    private func observeState() {
        Task {
            for await activity in await captureService.$captureActivity.values {
                if activity.willCapture {
                    flashScreen()
                } else {
                    captureActivity = activity
                }
            }
        }
    }
}
