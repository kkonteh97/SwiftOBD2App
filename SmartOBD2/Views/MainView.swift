//
//  TabView.swift
//  SmartOBD2
//
//  Created by kemo konteh on 8/5/23.
//

import SwiftUI
import CoreBluetooth

struct CarlyObd {
    static let elmServiceUUID = "FFE0"
    static let elmCharactericUUID = "FFE1"
}

struct MainView: View {
    let serviceUUID = CBUUID(string: CarlyObd.elmServiceUUID)
    let characteristicUUID = CBUUID(string: CarlyObd.elmCharactericUUID)
    @ObservedObject private var elm327: ELM327
    let sharedBLEManager = BLEManager.shared

    init() {
            // Create an instance of ELM327 using the shared BLEManager
            self.elm327 = ELM327(bleManager: sharedBLEManager)
        }

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
                TabView {
                    SettingsScreen(viewModel: SettingsScreenViewModel(elm327: elm327))
                        .tabItem {
                            Label("Settings", systemImage: "gear")
                        }
                    CarScreen(viewModel: CarScreenViewModel(elm327: elm327))
                        .tabItem {
                            Label("Car", systemImage: "car")
                        }

                    PIDView(viewModel: PIDViewModel(elm327: elm327))
                        .tabItem {
                            Label("Car", systemImage: "car")
                        }
                }
                .accentColor(.orange)
                .background(LinearGradient(Color.startColor(for: colorScheme), Color.endColor(for: colorScheme)))
                .tabViewStyle(.page(indexDisplayMode: .never))
                .navigationBarHidden(true)
            }
}

struct VINResults: Codable {
    let results: [VINInfo]
}

struct VINInfo: Codable, Hashable {
    let make: String
    let model: String
    let modelYear: String
    let engineCylinders: String
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
