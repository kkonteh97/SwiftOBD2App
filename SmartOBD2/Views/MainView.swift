//
//  TabView.swift
//  SmartOBD2
//
//  Created by kemo konteh on 8/5/23.
//

import SwiftUI
import CoreBluetooth





struct CarlyObd {
    static let ADAPTER_SCAN_INTERVAL = 500
    static let ADAPTER_SCAN_TIMEOUT = 30000
    static let ADAPTER_UPDATE_DELAY_BETWEEN_CHUNKS = 50
    static let BLE_BINARY_CONTINUOUS_MSG_FLAG = 187
    static let BLE_BINARY_LAST_MSG_FLAG = 190
    static var BLE_ELM_CHARACTERISTIC_UUID = "FFE1"
    static let BLE_DEEPDEBUG = false
    static var BLE_CHARACTERISTIC_DESCRIPTOR_UUID = 10498
    static let BLE_DEVICE_FIRMWARE_CHARACTERISTIC_UUID = 10790
    static let BLE_DEVICE_FIRMWARE_UUID = 6154
    static let BLE_ELM_SERVICE_UUID = "FFE0"
    static let BLE_WRITE_MAX_CHUNK_SIZE_BYTES = 20
    static let CODING_DELAY_BETWEEN_CHUNKS = 40
    static let RECEIVE_BUFFER_SIZE = 4096
    static let RECEIVE_BUFFER_SIZE_DDC = 8192
}

struct MainView: View {
    let serviceUUID = CBUUID(string: CarlyObd.BLE_ELM_SERVICE_UUID)
    let characteristicUUID = CBUUID(string: CarlyObd.BLE_ELM_CHARACTERISTIC_UUID)
    @ObservedObject private var elm327: ELM327
    let sharedBLEManager = BLEManager.shared

        
    init() {
            // Create an instance of ELM327 using the shared BLEManager
            self.elm327 = ELM327(bleManager: sharedBLEManager)
        }

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
            ZStack {
                LinearGradient(Color.startColor(for: colorScheme), Color.endColor(for: colorScheme))
                TabView {
                    SettingsScreen(viewModel: SettingsScreenViewModel(elm327: elm327, bleManager: sharedBLEManager))
                        .tabItem {
                            Label("Settings", systemImage: "gear")
                        }
                    CarScreen(viewModel: CarScreenViewModel(elmManager: elm327))
                        .tabItem {
                            Label("Car", systemImage: "car")
                        }
                }
                .navigationBarHidden(true)
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .always)) // Ensure the index view has a background
            }
            .ignoresSafeArea() // Extend the background color to the edges
        }
    }



struct VINResults: Codable {
    let Results: [VINInfo]
}

struct VINInfo: Codable, Hashable {
    let Make: String
    let Model: String
    let ModelYear: String
    let EngineCylinders: String
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
