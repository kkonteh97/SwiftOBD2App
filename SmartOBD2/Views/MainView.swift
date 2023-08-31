//
//  TabView.swift
//  SmartOBD2
//
//  Created by kemo konteh on 8/5/23.
//

import SwiftUI
import CoreBluetooth



extension String {
    subscript(offset: Int) -> Character {
        self[index(startIndex, offsetBy: offset)]
    }
}

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
    @StateObject private var bleManager: BLEManager
    @StateObject private var elm327: ELM327

    init() {
        let newBleManager = BLEManager(serviceUUID: serviceUUID, characteristicUUID: characteristicUUID)
        let newElm327 = ELM327(bleManager: newBleManager)
        _bleManager = StateObject(wrappedValue: newBleManager)
        _elm327 = StateObject(wrappedValue: newElm327)
    }
    
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            LinearGradient(colorScheme == .dark ? Color.darkStart : Color.lightStart, colorScheme == .dark ? Color.darkEnd : Color.lightEnd)
                .edgesIgnoringSafeArea(.all)
            TabView {
                SettingsScreen(viewModel: SettingsScreenViewModel(elmManager: elm327))
        
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
                CarScreen()
                    .tabItem {
                        Label("Car", systemImage: "car")
                    }
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .never))
        }
    }
}

extension Color {
    static let darkStart = Color(red: 50 / 255, green: 60 / 255, blue: 65 / 255)
    static let darkEnd = Color(red: 25 / 255, green: 25 / 255, blue: 30 / 255)
    static let lightStart = Color(red: 240 / 255, green: 240 / 255, blue: 246 / 255)
    static let lightEnd = Color(red: 120 / 255, green: 120 / 255, blue: 123 / 255)

    static func startColor(for colorScheme: ColorScheme) -> Color {
        return colorScheme == .dark ? .darkStart : .lightStart
    }

    static func endColor(for colorScheme: ColorScheme) -> Color {
        return colorScheme == .dark ? .darkEnd : .lightEnd
    }
}

extension LinearGradient {
    init(_ colors: Color...) {
        self.init(gradient: Gradient(colors: colors), startPoint: .topLeading, endPoint: .bottomTrailing)
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
