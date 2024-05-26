//
//  ZenbilApp.swift
//  Zenbil
//
//  Created by Berhan Witte on 09.05.24.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct YourApp: App {
    // Register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    // Create an instance of ScannerViewModel
    @State private var scannerViewModel = ScannerViewModel()

    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
                    .environment(scannerViewModel) // Provide ScannerViewModel to the environment
            }
        }
    }
}
