//
//  ScannerView.swift
//  Zenbil
//
//  Created by Berhan Witte on 11.05.24.
//

import SwiftUI

struct ScannerView: UIViewControllerRepresentable {
    
    @Environment(ScannerViewModel.self) var viewModel: ScannerViewModel
    
    var onScanCompleted: (String) -> Void

    func makeUIViewController(context: Context) -> ScannerVC {
        let scannerVC = ScannerVC()
        scannerVC.onScanCompleted = onScanCompleted
        scannerVC.viewModel = viewModel
        return scannerVC
    }

    func updateUIViewController(_ uiViewController: ScannerVC, context: Context) {
        // Ensure the view controller's mode matches the view model's state
        if uiViewController.isQRMode != viewModel.isQRMode {
            if viewModel.isQRMode {
                uiViewController.configureSessionForQR()
            } else {
                uiViewController.configureSessionForCamera()
            }
        }
    }
}

struct ScannerView_Previews: PreviewProvider {
    static var previews: some View {
        ScannerView { code in
            print("Scanned code: \(code)")
        }
        .environment(ScannerViewModel())
    }
}
