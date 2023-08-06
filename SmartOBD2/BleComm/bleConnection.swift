//
//  bleConnection.swift
//  Obd2Scanner
//
//  Created by kemo konteh on 8/3/23.
//

import Foundation
import CoreBluetooth

class BluetoothViewModel: NSObject, ObservableObject, CBPeripheralDelegate {
    
    private var elm = ELMComm()
    @Published var receivedDataBuffer = ""
    @Published var rpm: Int = 0
    
    
    private var centralManager: CBCentralManager!
    @Published var obd2Device: CBPeripheral?
    @Published var peripherals: [CBPeripheral] = []
    @Published var connectedPeripheral: CBPeripheral?
    @Published var peripheralsNames: [String] = []
    @Published var carly: String = ""
    @Published var characteristicsFound: [CBCharacteristic] = []
    @Published var connected: Bool = false
    @Published var initialized: Bool = false
    @Published var test: [CBService:[CBCharacteristic]] = [:]
    @Published var initCommands = ["ATZ\r\n", "ATE1\r\n","ATM0\r\n", "ATL0\r\n", "ATH1\r\n", "ATSP7\r\n", "ATAT1\r\n", "ATSTF0\r\n", "ATDPN\r\n", "ATS1\r\n"]
    private var getVoltageCommand = "ATRV"
    private let ecuServiceUUID = UUID(uuidString: "FFE0")
    @Published var ecuCharacteristicUUID = UUID(uuidString: "FFE1")
    @Published var ecuCharacteristic: CBCharacteristic?
    private let rpmPattern = "([0-9A-Fa-f]{2})\\s([0-9A-Fa-f]{2})\\s55\\s55\\s55"
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func processData(response: String) {
        let range = response.range(of: rpmPattern, options: .regularExpression)
        guard let matchedRange = range else {
            return
        }
        
        let rpmData = response[matchedRange]
        self.rpm = elm.processBuffer(rpmData:rpmData)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error reading characteristic value: \(error.localizedDescription)")
            return
        }
        switch characteristic.uuid.uuidString {
        case "FFE1":
            if let response = characteristic.value {
                guard let responseString = String(data: response, encoding: .utf8) else {
                    print("Invalid data format")
                    return
                }
                self.processData(response: responseString)
            }
        case "F000FFC1-0451-4000-B000-000000000000":
            if let response = characteristic.value {
                guard let responseString = String(data: response, encoding: .utf8) else {
                    print("Invalid data format")
                    return
                }
                print(responseString)
            }
        case "2A24":
            if let response = characteristic.value {
                guard let responseString = String(data: response, encoding: .utf8) else {
                    print("Invalid data format")
                    return
                }
                print(responseString)
            }
        case "2A26":
            if let response = characteristic.value {
                guard let responseString = String(data: response, encoding: .utf8) else {
                    print("Invalid data format")
                    return
                }
                print("Manufacturer: \(responseString))")
            }
            
        default:
            print("Unknown characteristic")
        }
    }
    
    func discoverDescriptors(peripheral: CBPeripheral, characteristic: CBCharacteristic) {
        peripheral.discoverDescriptors(for: characteristic)
    }
    
}

extension BluetoothViewModel: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            // Scan for peripherals if BLE is turned on
            self.centralManager?.scanForPeripherals(withServices: nil)
        case .poweredOff:
            // Alert user to turn on Bluetooth
            break
            
        case .resetting:
            // Wait for next state update and consider logging interruption of Bluetooth service
            break
        case .unauthorized:
            // Alert user to enable Bluetooth permission in app Settings
            break
        case .unsupported:
            // Alert user their device does not support Bluetooth and app will not work as expected
            break
            
        case .unknown:
            // Wait for next state update
            break
        @unknown default:
            fatalError()
        }
    }
    
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        // Check if the peripheral is BLE (advertisement data contains the CBAdvertisementDataIsConnectable key with a value of true)
        if let peripheralName = peripheral.name?.lowercased(), peripheralName.hasPrefix("carly") {
            centralManager.stopScan()
            obd2Device = peripheral
            centralManager.connect(peripheral, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to peripheral: \(peripheral.name ?? "Unnamed")")
        connectedPeripheral = peripheral
        peripheral.delegate = self // Set the delegate of the connected peripheral
        self.connected = true
        self.carly = peripheral.name ?? ""
        peripheral.discoverServices(nil) // Start discovering all services of the connected peripheral
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to peripheral: \(peripheral.name ?? "Unnamed")")
        connectedPeripheral = nil
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        self.connected = false
        self.initialized = false
    }
    
    func connect(to peripheral: CBPeripheral) {
        centralManager?.connect(peripheral, options: nil)
    }
    
}
