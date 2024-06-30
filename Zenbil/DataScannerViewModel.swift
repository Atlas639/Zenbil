//
//  DataScannerViewModel.swift
//  Zenbil
//
//  Created by Berhan Witte on 28.06.24.
//


import SwiftUI

@Observable class DataScannerViewModel {
    var recognizedTexts: [RecognizedTextItem] = []
    var recognizedBarcodes: [RecognizedBarcodeItem] = []

    func addRecognizedText(_ text: RecognizedTextItem) {
        print("Recognized text: \(text.transcript)")
        recognizedTexts.append(text)
    }

    func addRecognizedBarcode(_ barcode: RecognizedBarcodeItem) {
        print("Recognized barcode: \(barcode.payloadStringValue)")
        recognizedBarcodes.append(barcode)
    }
}

