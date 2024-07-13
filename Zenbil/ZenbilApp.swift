//
//  ZenbilApp.swift
//  Zenbil
//
//  Created by Berhan Witte on 09.05.24.
//

import SwiftUI
import FirebaseCore
import os

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct YourApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State private var vm = AppViewModel()

    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
                    .environment(vm)
                    .task {
                        await vm.requestDataScannerAccessStatus()
                    }
            }
        }
    }
}


let logger = Logger()
