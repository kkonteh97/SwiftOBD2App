//
//  bleConnection.swift
//  Obd2Scanner
//
//  Created by kemo konteh on 8/3/23.
//

import Foundation
import CoreBluetooth
import OSLog



class BLEManager: NSObject, CBPeripheralDelegate, ObservableObject, CBCentralManagerDelegate {
    
    // MARK: Properties
    let logger = Logger.bleCom
    

            
    //BLUETOOTH
    @Published var connectedPeripheral: CBPeripheral?
    @Published var characteristics: [CBCharacteristic] = []
    @Published var peripherals: [CBPeripheral] = []
    @Published var services: [CBPeripheral] = []
    @Published var ecuCharacteristic: CBCharacteristic?
    @Published var elmAdapter: CBPeripheral?
    private var centralManager: CBCentralManager?

    
    @Published var connected: Bool = false
    
    @Published var history: [String] = []
    
    
    let BLE_ELM_SERVICE_UUID: CBUUID
    let BLE_ELM_CHARACTERISTIC_UUID: CBUUID
    var linesToParse = [String]()
    var adapterReady = false
    
    
    // MARK: Initialization

    init(serviceUUID: CBUUID, characteristicUUID: CBUUID) {
        self.BLE_ELM_SERVICE_UUID = serviceUUID
        self.BLE_ELM_CHARACTERISTIC_UUID = characteristicUUID
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: Central Manager Delegate Methods

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            // Scan for peripherals if BLE is turned on
            logger.debug("Bluetooth is On.")
            self.centralManager?.scanForPeripherals(withServices: [BLE_ELM_SERVICE_UUID], options: nil)
            
        case .poweredOff:
            logger.warning("Bluetooth is currently powered off.")
            self.connected = false
            
        case .resetting:
            logger.warning("Bluetooth is resetting.")
        default:
            fatalError()
        }
    }


    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        // ... (peripheral discovery logic)
        if let name = peripheral.name {
            if name.contains("Carly") {
                logger.debug("Found Carly Adapter")
                centralManager?.stopScan()
                elmAdapter = peripheral
                connect(to: peripheral)
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        logger.debug("Connected to peripheral: \(peripheral.name ?? "Unnamed")")
        connectedPeripheral = peripheral
        peripheral.delegate = self // Set the delegate of the connected peripheral
        self.connected = true
        peripheral.discoverServices(nil) // Start discovering all services of the connected peripheral
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        logger.error("Failed to connect to peripheral: \(peripheral.name ?? "Unnamed")")
        connectedPeripheral = nil
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        self.connected = false
        logger.warning("Disconnected from peripheral: \(peripheral.name ?? "Unnamed")")
    }
    
    // MARK: Peripheral Delegate Methods

    func connect(to peripheral: CBPeripheral) {
        // ... (peripheral connection logic)
        centralManager?.connect(peripheral, options: nil)
        connectedPeripheral = peripheral
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        // ... (discovering services logic)
        if let error = error {
            logger.error("Error discovering services: \(error.localizedDescription)")
            return
        }
        if let services = peripheral.services {
            for service in services {
                logger.info("Found Service: \(service)")
                if service.uuid == BLE_ELM_SERVICE_UUID {
                    peripheral.discoverCharacteristics(nil, for: service)
                } else {
                }
            }
        }
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else {
            logger.error("No characteristics found")
            return
        }
        
        for characteristic in characteristics {
            self.characteristics.append(characteristic)
            switch characteristic.uuid {
            case BLE_ELM_CHARACTERISTIC_UUID:
                ecuCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
                self.adapterReady = true
                logger.info("Adapter Ready")
            default:
                logger.info("Unhandled Characteristic UUID: \(characteristic.uuid)")
                if characteristic.properties.contains(.notify) {
                    peripheral.setNotifyValue(true, for: characteristic)
                    
                }
            }
        }
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            logger.error("Error reading characteristic value: \(error.localizedDescription)")
            return
        }
        switch characteristic.uuid.uuidString {
        case BLE_ELM_CHARACTERISTIC_UUID.uuidString:
            guard let characteristicValue = characteristic.value else {
                return
            }
            
            processReceivedData(characteristicValue, completion: sendMessageCompletion)
            
            
        case "F000FFC1-0451-4000-B000-000000000000":
            if let response = characteristic.value {
                guard let responseString = String(data: response, encoding: .utf8) else {
                    print("Invalid data format")
                    return
                }
                print("Manufacturer: \(responseString))")
            }
        case "2A24":
            if let response = characteristic.value {
                guard let responseString = String(data: response, encoding: .utf8) else {
                    print("Invalid data format")
                    return
                }
                logger.info("Manufacturer: \(responseString))")
            }
        case "2A26":
            if let response = characteristic.value {
                guard let responseString = String(data: response, encoding: .utf8) else {
                    print("Invalid data format")
                    return
                }
                logger.info("Manufacturer: \(responseString))")
            }
            
        default:
            logger.info("Unknown characteristic")
        }
    }
    
    func discoverDescriptors(peripheral: CBPeripheral, characteristic: CBCharacteristic) {
        peripheral.discoverDescriptors(for: characteristic)
    }
    

    
    // MARK: Sending Messages
    var sendMessageCompletion: ((String?, Error?) -> Void)?

    
    func sendMessageAsync(_ message: String) async throws -> String {
        // ... (sending message logic)
        let message = "\(message)\r"
        logger.info("Sending: \(message)")
        
        guard let connectedPeripheral = self.connectedPeripheral,
              let ecuCharacteristic = self.ecuCharacteristic,
              let data = message.data(using: .ascii) else {
                logger.error("Error: Missing peripheral or characteristic.")
                throw SendMessageError.missingPeripheralOrCharacteristic
        }
        
        connectedPeripheral.writeValue(data, for: ecuCharacteristic, type: .withResponse)
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            // Set up a timeout timer
                self.sendMessageCompletion = { response, error in
                    if let response = response {
                        continuation.resume(returning: response)

                    } else if let error = error {
                        continuation.resume(throwing: error)

                    } else {
                        continuation.resume(throwing: SendMessageError.timeout)
                    }
                }
        }
    }
    
    
    func handleResponse(completion: ((String, Error) -> Void)?) {
        let strippedResponse = linesToParse.map { $0.replacingOccurrences(of: ">", with: "") }.joined()
        logger.info("Response: \(strippedResponse)")
        sendMessageCompletion?(strippedResponse, nil)
        linesToParse.removeAll()
    }
    
    
    func processReceivedData(_ data: Data, completion: ((String, Error) -> Void)?) {
        guard let cleanedResponse = String(data: data, encoding: .utf8)?.replacingOccurrences(of: "[\r\n]+", with: "", options: .regularExpression) else {
            return
        }
        
        let chunkSize = 8
        var index = cleanedResponse.startIndex
        while index < cleanedResponse.endIndex {
            let endIndex = cleanedResponse.index(index, offsetBy: chunkSize, limitedBy: cleanedResponse.endIndex) ?? cleanedResponse.endIndex
            let chunk = cleanedResponse[index..<endIndex]
            
            self.linesToParse.append(String(chunk))
            
            if chunk.contains(">") {
                handleResponse(completion: completion)
            }
            
            index = endIndex
        }
    }
    
    
    enum SendMessageError: Error {
        case missingPeripheralOrCharacteristic
        case timeout
    }
}

