//
//  SmartOBD2App.swift
//  SmartOBD2
//
//  Created by kemo konteh on 8/3/23.
//

import SwiftUI
import OSLog

extension Logger {
    /// Using your bundle identifier is a great way to ensure a unique identifier.
    private static var subsystem = Bundle.main.bundleIdentifier!

    /// Logs the view cycles like a view that appeared.
    static let elmCom = Logger(subsystem: subsystem, category: "ELM327")

    /// All logs related to tracking and analytics.
    static let bleCom = Logger(subsystem: subsystem, category: "BLEComms")
}

@main
struct SmartOBD2App: App {
    let sharedBLEManager = BLEManager.shared
    @ObservedObject private var elm327: ELM327

    init() {
            // Create an instance of ELM327 using the shared BLEManager
            self.elm327 = ELM327(bleManager: sharedBLEManager)
    }
    var body: some Scene {
        WindowGroup {
            MainView(viewModel: SettingsScreenViewModel(elm327: elm327))
        }
    }
}
