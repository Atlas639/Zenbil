//
//  DataScannerModel.swift
//  Zenbil
//
//  Created by Berhan Witte on 28.06.24.
//

import Foundation
import SwiftUI
import VisionKit

struct SessionData: Identifiable {
    var id: UUID
    var barcodes: [RecognizedBarcodeItem] = []
    var texts: [RecognizedTextItem] = []
}

struct RecognizedTextItem {
    var transcript: String
    var bounds: RecognizedItem.Bounds
    var id: UUID
}

struct RecognizedBarcodeItem {
    var payloadStringValue: String
    var bounds: RecognizedItem.Bounds
    var id: UUID
}

struct Article: Identifiable {
    var id = UUID() // Generates a unique identifier for each article
    var text: String // The scanned text
    var barcode: String // The scanned barcode
    var photos: [UIImage] // Array of photos for the article
}
