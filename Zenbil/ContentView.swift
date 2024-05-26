//
//  ContentView.swift
//  Zenbil
//
//  Created by Berhan Witte on 09.05.24.
//

import SwiftUI

extension View {
    func withoutAnimation(action: @escaping () -> Void) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            action()
        }
    }
}

struct ContentView: View {
    @State private var showOptions: Bool = false // State to toggle the visibility of options
    @State private var articleName: String = ""
    @State private var showScanner: Bool = false
    @State private var isScannerViewVisible: Bool = false
    @State private var scannedCode: String?
    @Environment(ScannerViewModel.self) var viewModel: ScannerViewModel

    // Dummy data for articles
    let articles = [
        (name: "Article 1", description: "Description of Article 1."),
        (name: "Article 2", description: "Description of Article 2."),
        (name: "Article 3", description: "Description of Article 3.")
    ]

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading, spacing: 16) {
                // List of articles
                List(articles, id: \.name) { article in
                    HStack {
                        // Image Placeholder
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray)
                            .frame(width: 50, height: 50)

                        VStack(alignment: .leading) {
                            // Article Name
                            Text(article.name)
                                .font(.headline)

                            // Article Description
                            Text(article.description)
                                .font(.subheadline)
                        }
                    }
                }
                Spacer()
            }

            // Floating Action Button with Expanding Options
            VStack(spacing: 16) {
                if showOptions {
                    Button(action: {
                        withoutAnimation {
                            showScanner = true
                            showOptions = false
                        }
                    }) {
                        Label("Add Article", systemImage: "doc")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .shadow(radius: 4)
                    }
                }
                Button(action: {
                    withAnimation {
                        showOptions.toggle()
                    }
                }) {
                    Image(systemName: "plus")
                        .rotationEffect(.degrees(showOptions ? 45 : 0)) // Rotate '+' to 'x' when options are shown
                        .font(.largeTitle)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .clipShape(Circle())
                        .shadow(radius: 10)
                }
            }
            .padding(20)
            .fullScreenCover(isPresented: $showScanner) {
                ScannerView { result in
                    scannedCode = result // Handle the scanned code as needed
                    withoutAnimation {
                        showScanner = false
                        showOptions = false
                    }
                }
                .environment(viewModel) // Ensure ScannerView has access to the environment object
                .edgesIgnoringSafeArea(.all)
            }
        }
    }
}

// Helper View for Option Buttons
struct OptionButton: View {
    var icon: String
    var label: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.white)
                Text(label)
                    .foregroundColor(.white)
            }
            .padding()
            .background(Color.blue)
            .cornerRadius(10)
            .shadow(radius: 4)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(ScannerViewModel()) // Provide ScannerViewModel to the environment for previews
    }
}

struct ProductData: Codable {
    let productName: String
}
