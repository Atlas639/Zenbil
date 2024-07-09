//
//  SessionDataModel.swift
//  Zenbil
//
//  Created by Berhan Witte on 06.07.24.
//

import Foundation
import SwiftUI
import VisionKit

struct SessionData: Identifiable {
    var id: UUID
    var items: [ItemData] = []
    var barcodes: [RecognizedBarcodeItem] = []
    var texts: [RecognizedTextItem] = []
}

struct ItemData: Identifiable {
    var id: UUID
    var barcodes: [RecognizedBarcodeItem] = []
    var texts: [RecognizedTextItem] = []
/// var images:
    
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

