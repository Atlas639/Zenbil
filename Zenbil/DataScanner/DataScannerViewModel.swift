//
//  DataScannerViewModel.swift
//  Zenbil
//
//  Created by Berhan Witte on 27.05.24.
//

import AVKit
import Foundation
import SwiftUI
import VisionKit

enum ScanType {
    case barcode, text
}

enum DataScannerAccessStatusType {
    case notDetermined
    case cameraAccessNotGranted
    case cameraNotAvailable
    case scannerAvailable   
    case scannerNotAvailable
}

@MainActor
@Observable final class AppViewModel {
    
    var dataScannerAccessStatus: DataScannerAccessStatusType = .notDetermined
    var recognizedItems: [RecognizedItem] = []
    var scanType: ScanType = .barcode
    var textContentType: DataScannerViewController.TextContentType?
    var recognizesMultipleItems = true
    
    var recognizedDataType: DataScannerViewController.RecognizedDataType{
        scanType == .barcode ? .barcode() : .text(textContentType: textContentType)
    }
    
    private var isScannerAvailable: Bool {
        DataScannerViewController.isAvailable && DataScannerViewController.isSupported
    }
    
    func requestDataScannerAccessStatus () async {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            dataScannerAccessStatus = .cameraNotAvailable
            return
        }
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            
        case .authorized:
            dataScannerAccessStatus = isScannerAvailable ? .scannerAvailable : .scannerNotAvailable
            
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            if granted {
                dataScannerAccessStatus = isScannerAvailable ? .scannerAvailable : .scannerNotAvailable
            } else {
                dataScannerAccessStatus = .cameraAccessNotGranted
            }
            
        default : break
            
        }
        
    }
    
}
