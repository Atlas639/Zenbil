//
//  ScannerViewModel.swift
//  Zenbil
//
//  Created by Berhan Witte on 13.05.24.
//


import SwiftUI

@Observable class ScannerViewModel {
    var isQRMode: Bool = true
    var thumbnails: [UIImage] = []
    var articles: [Article] = []
    var selectedIndex: Int?
    
    init() {
        // Initialize with a default article
        addNewArticle(qrCode: "Placeholder QR Code")
    }
    
    func addNewArticle(qrCode: String) {
        let newArticle = Article(qrCode: qrCode, photos: [])
        articles.append(newArticle)
        selectedIndex = articles.count - 1
    }
    
    func replaceQRCodeForCurrentArticle(newQRCode: String) {
        guard let selectedIndex = selectedIndex, selectedIndex < articles.count else { return }
        articles[selectedIndex].qrCode = newQRCode
    }
    
    func addPhotoToCurrentArticle(photo: UIImage) {
        guard let selectedIndex = selectedIndex, selectedIndex < articles.count else { return }
        articles[selectedIndex].photos.append(photo)
    }
    
    func resetData() {
        articles.removeAll()
        thumbnails.removeAll()
        selectedIndex = nil
        isQRMode = true
    }
}

struct Article {
    var qrCode: String
    var photos: [UIImage]
}


//
//  NoAnimationModifier.swift
//  Zenbil
//
//  Created by Berhan Witte on 18.05.24.
//

import SwiftUI

class CustomHostingController<Content: View>: UIHostingController<Content> {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false) // Disable the default animation
    }
}

struct NoAnimationFullScreenCover<Content: View>: UIViewControllerRepresentable {
    let isPresented: Binding<Bool>
    let content: Content

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if isPresented.wrappedValue && uiViewController.presentedViewController == nil {
            let hostingController = CustomHostingController(rootView: content)
            hostingController.modalPresentationStyle = .fullScreen
            uiViewController.present(hostingController, animated: false)
        } else if !isPresented.wrappedValue && uiViewController.presentedViewController != nil {
            uiViewController.dismiss(animated: false)
        }
    }
}

struct NoAnimationModifier<OverlayContent: View>: ViewModifier {
    let overlayContent: OverlayContent
    @Binding var isPresented: Bool

    func body(content: Content) -> some View {
        content
            .background(
                NoAnimationFullScreenCover(isPresented: $isPresented, content: overlayContent)
            )
    }
}

extension View {
    func noAnimationFullScreenCover<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        self.modifier(NoAnimationModifier(overlayContent: content(), isPresented: isPresented))
    }
}
