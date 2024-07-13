//
//  DataCaptureView.swift	//  Zenbil
//
//  Created by Berhan Witte on 28.05.24.
//

import SwiftUI
import VisionKit
import AVFoundation

struct DataScannerView: UIViewControllerRepresentable {
    @Binding var recognizedItems: [RecognizedItem]
    let recognizedDataTypes: Set<DataScannerViewController.RecognizedDataType>
    let recognizesMultipleItems: Bool
    @Binding var sessions: [SessionData]
    @Binding var activeSession: UUID?
    @Binding var activeItem: UUID?
    
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
        return vc
    }
    
    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        uiViewController.delegate = context.coordinator
        try? uiViewController.startScanning()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(
            recognizedItems: $recognizedItems,
            sessions: $sessions,
            activeSession: $activeSession,
            activeItem: $activeItem)
    }
    
    static func dismantleUIViewController(_ uiViewController: DataScannerViewController, coordinator: Coordinator) {
        uiViewController.stopScanning()
    }
    
    class Coordinator: NSObject, DataScannerViewControllerDelegate, AVCapturePhotoCaptureDelegate {
        @Binding var recognizedItems: [RecognizedItem]
        @Binding var sessions: [SessionData]
        @Binding var activeSession: UUID?
        @Binding var activeItem: UUID?
        
        init(
            recognizedItems: Binding<[RecognizedItem]>,
            sessions: Binding<[SessionData]>,
            activeSession: Binding<UUID?>,
            activeItem: Binding<UUID?>
        ) {
            self._recognizedItems = recognizedItems
            self._sessions = sessions
            self._activeSession = activeSession
            self._activeItem = activeItem
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
                    if let sessionIndex = sessions.firstIndex(where: { $0.id == activeSession }),
                       let itemIndex = sessions[sessionIndex].items.firstIndex(where: { $0.id == activeItem })
                    {
                        sessions[sessionIndex].items[itemIndex].texts.append(recognizedTextItem)
                        print("Current text items in active item: \(sessions[sessionIndex].items[itemIndex].texts)")
                    }
                case .barcode(let barcode):
                    let recognizedBarcodeItem = RecognizedBarcodeItem(
                        payloadStringValue: barcode.payloadStringValue ?? "",
                        bounds: barcode.bounds,
                        id: barcode.id
                    )
                    if let sessionIndex = sessions.firstIndex(where: { $0.id == activeSession }),
                       let itemIndex = sessions[sessionIndex].items.firstIndex(where: { $0.id == activeItem }) {
                        sessions[sessionIndex].items[itemIndex].barcodes.append(recognizedBarcodeItem)
                        print("Current barcode items in active item: \(sessions[sessionIndex].items[itemIndex].barcodes)")
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
    }
}
