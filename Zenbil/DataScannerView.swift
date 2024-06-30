//
//  DataScannerView.swift	//  Zenbil
//
//  Created by Berhan Witte on 28.05.24.
//

import SwiftUI
import VisionKit

struct DataScannerView: UIViewControllerRepresentable {
    @Binding var recognizedItems: [RecognizedItem]
    let recognizedDataTypes: Set<DataScannerViewController.RecognizedDataType>
    let recognizesMultipleItems: Bool
    let viewModel: DataScannerViewModel

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
        Coordinator(recognizedItems: $recognizedItems, viewModel: viewModel)  // Update this line
    }

    static func dismantleUIViewController(_ uiViewController: DataScannerViewController, coordinator: Coordinator) {
        uiViewController.stopScanning()
    }

    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        @Binding var recognizedItems: [RecognizedItem]
        var viewModel: DataScannerViewModel

        init(recognizedItems: Binding<[RecognizedItem]>, viewModel: DataScannerViewModel) {
            self._recognizedItems = recognizedItems
            self.viewModel = viewModel
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            // print("didTapOn \(item)")
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            recognizedItems.append(contentsOf: addedItems)
            // print("didAddItems \(addedItems)")

            for item in addedItems {
                switch item {
                case .text(let text):
                    let recognizedTextItem = RecognizedTextItem(
                        transcript: text.transcript,
                        bounds: text.bounds,
                        id: text.id
                    )
                    viewModel.addRecognizedText(recognizedTextItem)
                case .barcode(let barcode):
                    let recognizedBarcodeItem = RecognizedBarcodeItem(
                        payloadStringValue: barcode.payloadStringValue ?? "",
                        bounds: barcode.bounds,
                        id: barcode.id
                    )
                    viewModel.addRecognizedBarcode(recognizedBarcodeItem)
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
