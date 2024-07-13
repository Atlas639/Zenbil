//
//  PhotoCaptureView.swift
//  Zenbil
//
//  Created by Berhan Witte on 10.07.24.
//

import SwiftUI
import AVFoundation

struct PhotoCaptureView: UIViewControllerRepresentable {
    @Binding var sessions: [SessionData]
    @Binding var activeSession: UUID?
    @Binding var activeItem: UUID?
    @Binding var capturedImage: UIImage?
    @Binding var capturePhoto: Bool

    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        context.coordinator.setupCaptureSession(in: vc.view)
        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if capturePhoto {
            context.coordinator.capturePhoto()
            DispatchQueue.main.async {
                capturePhoto = false
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            sessions: $sessions,
            activeSession: $activeSession,
            activeItem: $activeItem,
            capturedImage: $capturedImage
        )
    }

    class Coordinator: NSObject, AVCapturePhotoCaptureDelegate {
        @Binding var sessions: [SessionData]
        @Binding var activeSession: UUID?
        @Binding var activeItem: UUID?
        @Binding var capturedImage: UIImage?
        var captureSession: AVCaptureSession?
        var photoOutput: AVCapturePhotoOutput?

        init(
            sessions: Binding<[SessionData]>,
            activeSession: Binding<UUID?>,
            activeItem: Binding<UUID?>,
            capturedImage: Binding<UIImage?>
        ) {
            self._sessions = sessions
            self._activeSession = activeSession
            self._activeItem = activeItem
            self._capturedImage = capturedImage
        }

        func setupCaptureSession(in view: UIView) {
            captureSession = AVCaptureSession()
            guard let captureSession = captureSession else { return }

            captureSession.beginConfiguration()
            let videoDevice = AVCaptureDevice.default(for: .video)
            guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice!), captureSession.canAddInput(videoDeviceInput) else { return }
            captureSession.addInput(videoDeviceInput)

            photoOutput = AVCapturePhotoOutput()
            guard let photoOutput = photoOutput, captureSession.canAddOutput(photoOutput) else { return }
            captureSession.addOutput(photoOutput)

            captureSession.commitConfiguration()

            let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = view.bounds
            view.layer.addSublayer(previewLayer)

            captureSession.startRunning()
        }

        func capturePhoto() {
            print("Capture photo started")
            let settings = AVCapturePhotoSettings()
            photoOutput?.capturePhoto(with: settings, delegate: self)
        }

        func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
            print("Finished processing photo")
            guard error == nil, let data = photo.fileDataRepresentation() else {
                print("Error during photo processing: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            capturedImage = UIImage(data: data)
            print("Photo captured and saved to state")

            guard let capturedImage = capturedImage else {
                print("Captured image is nil.")
                return
            }

            guard let activeSession = activeSession else {
                print("Active session is nil.")
                return
            }

            guard let activeItem = activeItem else {
                print("Active item is nil.")
                return
            }

            guard let sessionIndex = sessions.firstIndex(where: { $0.id == activeSession }) else {
                print("Active session not found in sessions.")
                return
            }

            print("Session index: \(sessionIndex)")

            guard let itemIndex = sessions[sessionIndex].items.firstIndex(where: { $0.id == activeItem }) else {
                print("Active item not found in session.")
                return
            }

            print("Item index: \(itemIndex)")

            sessions[sessionIndex].items[itemIndex].images.append(capturedImage)
            print("Photo appended to session \(sessions[sessionIndex].id) item \(sessions[sessionIndex].items[itemIndex].id)")
            print("Total images in item: \(sessions[sessionIndex].items[itemIndex].images.count)")
        }
    }
}
