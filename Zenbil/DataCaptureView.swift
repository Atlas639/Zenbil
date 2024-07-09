//
//  DataCaptureView.swift	//  Zenbil
//
//  Created by Berhan Witte on 28.05.24.
//

import SwiftUI
import VisionKit
import AVFoundation

struct DataCaptureView: UIViewControllerRepresentable {
    @Binding var recognizedItems: [RecognizedItem]
    let recognizedDataTypes: Set<DataScannerViewController.RecognizedDataType>
    let recognizesMultipleItems: Bool
    @Binding var sessions: [SessionData]
    @Binding var activeSession: UUID?
    @Binding var activeItem: UUID?
    @Binding var capturedImage: UIImage?
    @Binding var capturePhoto: Bool

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let vc = DataScannerViewController(
            recognizedDataTypes: recognizedDataTypes,
            qualityLevel: .balanced,
            recognizesMultipleItems: recognizesMultipleItems,
            isHighFrameRateTrackingEnabled: true,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: false
        )
        vc.delegate = context.coordinator
        context.coordinator.setupCaptureSession()
        return vc
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        uiViewController.delegate = context.coordinator
        try? uiViewController.startScanning()
        
        if capturePhoto {
            context.coordinator.capturePhoto()
            DispatchQueue.main.async {
                capturePhoto = false
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            recognizedItems: $recognizedItems,
            sessions: $sessions,
            activeSession: $activeSession,
            activeItem: $activeItem, 
            capturedImage: $capturedImage)
    }

    static func dismantleUIViewController(_ uiViewController: DataScannerViewController, coordinator: Coordinator) {
        uiViewController.stopScanning()
        coordinator.stopCaptureSession()
    }

    class Coordinator: NSObject, DataScannerViewControllerDelegate, AVCapturePhotoCaptureDelegate {
        @Binding var recognizedItems: [RecognizedItem]
        @Binding var sessions: [SessionData]
        @Binding var activeSession: UUID?
        @Binding var activeItem: UUID?
        @Binding var capturedImage: UIImage?
        var captureSession: AVCaptureSession?
        var photoOutput: AVCapturePhotoOutput?

        init(
            recognizedItems: Binding<[RecognizedItem]>,
            sessions: Binding<[SessionData]>,
            activeSession: Binding<UUID?>,
            activeItem: Binding<UUID?>,
            capturedImage: Binding<UIImage?>
        ) {
            self._recognizedItems = recognizedItems
            self._sessions = sessions
            self._activeSession = activeSession
            self._activeItem = activeItem
            self._capturedImage = capturedImage
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            // print("didTapOn \(item)")
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            recognizedItems.append(contentsOf: addedItems)
            // print("didAddItems \(addedItems)")
            
            guard let activeSession = activeSession else { return }

            for item in addedItems {
                switch item {
                case .text(let text):
                    let recognizedTextItem = RecognizedTextItem(
                        transcript: text.transcript,
                        bounds: text.bounds,
                        id: text.id
                    )
                    print("Recognized text: \(text.transcript)")
                    if let index = sessions.firstIndex(where: { $0.id == activeSession }) {
                        sessions[index].texts.append(recognizedTextItem)
                    }
                case .barcode(let barcode):
                    let recognizedBarcodeItem = RecognizedBarcodeItem(
                        payloadStringValue: barcode.payloadStringValue ?? "",
                        bounds: barcode.bounds,
                        id: barcode.id
                    )
                    print("Recognized barcode: \(barcode.payloadStringValue ?? "")")
                    if let index = sessions.firstIndex(where: { $0.id == activeSession }) {
                        sessions[index].barcodes.append(recognizedBarcodeItem)
                    }
                @unknown default:
                    print("Unknown item type")
                }
            }
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didRemove removedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            self.recognizedItems = allItems.filter { item in
                !removedItems.contains(where: { $0.id == item.id })
            }
            // print("didRemovedItems \(removedItems)")
        }

        func dataScanner(_ dataScanner: DataScannerViewController, becomeUnavailableWithError error: DataScannerViewController.ScanningUnavailable) {
            print("become unavailable with error \(error.localizedDescription)")
        }
        
        func setupCaptureSession() {
            captureSession = AVCaptureSession()
            guard let captureSession = captureSession else { return }
            
            captureSession.beginConfiguration()
            let videoDevice = AVCaptureDevice.default(for :.video)
            guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice!), captureSession.canAddInput(videoDeviceInput) else { return }
            captureSession.addInput(videoDeviceInput)
            
            photoOutput = AVCapturePhotoOutput()
            guard let photoOutput = photoOutput, captureSession.canAddOutput(photoOutput) else { return }
            captureSession.addOutput(photoOutput)
            
            captureSession.commitConfiguration()
            captureSession.startRunning()
        }
        
        func capturePhoto() {
            print("Capture photo started")
            let settings = AVCapturePhotoSettings()
            photoOutput?.capturePhoto(with: settings, delegate: self)
        }
        
        func stopCaptureSession() {
            captureSession?.stopRunning()
            captureSession = nil
            photoOutput = nil
        }
        
        func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
            print("Finished processing photo")
            guard error == nil, let data = photo.fileDataRepresentation() else { return }
            capturedImage = UIImage(data: data)
            print("Photo captured and saved to state")
        }
    }
}
