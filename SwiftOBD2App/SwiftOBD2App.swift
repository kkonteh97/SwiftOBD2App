//
//  SmartOBD2App.swift
//  SmartOBD2
//
//  Created by kemo konteh on 8/3/23.
//

import SwiftUI
import OSLog
import SwiftOBD2

extension Logger {
    /// Using your bundle identifier is a great way to ensure a unique identifier.
    private static var subsystem = Bundle.main.bundleIdentifier!

    /// Logs the view cycles like a view that appeared.
    static let elmCom = Logger(subsystem: subsystem, category: "ELM327")

    /// All logs related to tracking and analytics.
    static let bleCom = Logger(subsystem: subsystem, category: "BLEComms")
}

class GlobalSettings: NSObject, ObservableObject {
    @Published var displayType: BottomSheetType = .quarterScreen
    @Published var statusMessage = ""
    @Published var showAltText = false
    @Published var connectionType: ConnectionType = .bluetooth {
        didSet {
            UserDefaults.standard.set(connectionType.rawValue, forKey: "connectionType")
        }
    }
    @Published var selectedUnit: MeasurementUnits = .metric {
        didSet {
            UserDefaults.standard.set(selectedUnit.rawValue, forKey: "selectedUnit")
        }
    }

    override init() {
        super.init()
        if let unit = UserDefaults.standard.string(forKey: "selectedUnit") {
            selectedUnit = MeasurementUnits(rawValue: unit) ?? .metric
        }
        if let connection = UserDefaults.standard.string(forKey: "connectionType") {
            connectionType = ConnectionType(rawValue: connection) ?? .bluetooth
        }
    }
}

@main
struct SMARTOBD2App: App {
    @StateObject var globalSettings = GlobalSettings()
    @StateObject var obdService = OBDService(connectionType: .bluetooth)
    @StateObject var garage = Garage()

    @State var SplashScreenIsActive: Bool = true

    var body: some Scene {
        WindowGroup {
            if SplashScreenIsActive {
                SplashScreenView(isActive: $SplashScreenIsActive)
            } else {
                MainView()
                    .environmentObject(globalSettings)
                    .environmentObject(garage)
                    .environmentObject(obdService)
            }
        }
    }
}
