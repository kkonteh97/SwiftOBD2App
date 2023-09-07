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
    @Published var peripherals: [CBPeripheral] = []
    @Published var ecuCharacteristic: CBCharacteristic?
    @Published var elmAdapter: CBPeripheral?
    private var centralManager: CBCentralManager?
    @Published var discoveredServicesAndCharacteristics: [(CBService, [CBCharacteristic])] = []
    @Published var connectionState: ConnectionState = .disconnected

    @Published var connected: Bool = false
    
    static let shared = BLEManager()
    
    var linesToParse = [String]()
    var adapterReady = false
    
    var sendMessageCompletion: ((String?, Error?) -> Void)?
    
    // MARK: Initialization

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: Central Manager Delegate Methods

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            // Scan for peripherals if BLE is turned on
            logger.debug("Bluetooth is On.")
            self.centralManager?.scanForPeripherals(withServices: [CBUUID(string: CarlyObd.BLE_ELM_SERVICE_UUID)], options: nil)
            connectionState = .connecting

            
        case .poweredOff:
            logger.warning("Bluetooth is currently powered off.")
            self.connected = false
            connectionState = .disconnected

            
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
                connect(to: peripheral)
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        logger.error("Failed to connect to peripheral: \(peripheral.name ?? "Unnamed")")
        elmAdapter = nil
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        self.connected = false
        logger.warning("Disconnected from peripheral: \(peripheral.name ?? "Unnamed")")
    }
    
    // MARK: Peripheral Delegate Methods
    var connectionCompletion: ((CBPeripheral) -> Void)?

    func connect(to peripheral: CBPeripheral) {
        // ... (peripheral connection logic)
        centralManager?.connect(peripheral, options: nil)
        elmAdapter = peripheral
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        logger.debug("Connected to peripheral: \(peripheral.name ?? "Unnamed")")
        elmAdapter = peripheral
        connectionState = .connectedToAdapter
        peripheral.delegate = self // Set the delegate of the connected peripheral
        peripheral.discoverServices(nil) // Start discovering all services of the connected peripheral
    }
    
    func scanAndConnectAsync(services: [CBUUID]) async throws -> CBPeripheral {
        // ... (peripheral connection logic)
        self.centralManager?.scanForPeripherals(withServices: services, options: nil)
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CBPeripheral, Error>) in
            // Set up a timeout timer
                self.connectionCompletion = { peripheral in
                    continuation.resume(returning: peripheral)
                }
        }
    }
    
    // MARK: Sending Messages

    
    func sendMessageAsync(_ message: String) async throws -> String {
        // ... (sending message logic)
        let message = "\(message)\r"
        logger.info("Sending: \(message)")
        
        guard let connectedPeripheral = self.elmAdapter,
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
    
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        // ... (discovering services logic)
        if let error = error {
            logger.error("Error discovering services: \(error.localizedDescription)")
            return
        }
        if let services = peripheral.services {
            for service in services {
                logger.info("Found Service: \(service)")
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else {
            logger.error("No characteristics found")
            return
        }
        self.discoveredServicesAndCharacteristics.append((service, characteristics))
        
        for characteristic in characteristics {
            switch characteristic.uuid.uuidString {
            case "FFE1":
                ecuCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
                connectionCompletion?(peripheral)
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
        case "FFE1":
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

