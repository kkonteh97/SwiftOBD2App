//
//  bleConnection.swift
//  Obd2Scanner
//
//  Created by kemo konteh on 8/3/23.
//

import Foundation
import CoreBluetooth
import Combine
import OSLog

enum ConnectionState {
    case notConnected
    case connectedToAdapter
    case connectedToVehicle
}

class BLEManager: NSObject, ObservableObject, CBPeripheralProtocolDelegate, CBCentralManagerProtocolDelegate {
    let logger = Logger.bleCom

    // MARK: Properties
    @Published var isSearching: Bool = false
    @Published var connectionState: ConnectionState = .notConnected
    // BLUETOOTH

    @Published var connectedPeripheral: CBPeripheralProtocol?
    @Published var foundPeripherals: [Peripheral] = []

    private var centralManager: CBCentralManagerProtocol!
    private var ecuCharacteristic: CBCharacteristic?

    static let RestoreIdentifierKey: String = "OBD2Adapter"

    var userDevice: DeviceInfo?

    var debug = true

    private var buffer = Data()

    private var sendMessageCompletion: (([String]?, Error?) -> Void)?
    private var foundPeripheralCompletion: ((Peripheral?, Error?) -> Void)?
    private var serviceDiscoveryCompletion: (([CBService]?, Error?) -> Void)?
    private var characteristicDiscoveryCompletion: (([CBCharacteristic]?, Error?) -> Void)?
    private var connectionCompletion: ((CBPeripheralProtocol?, Error?) -> Void)?


    // MARK: - Initialization
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil, options: nil)

//        #if targetEnvironment(simulator)
//        isDemoMode = true
//        #else
//        isDemoMode = false
//        #endif
    }

    func demoModeSwitch(_ isDemoMode: Bool) {
        // switch to mock manager in demo mode
        switch isDemoMode {
        case true:
            centralManager = CBCentralManagerMock(delegate: self, queue: nil)
        case false:
            centralManager = CBCentralManager(delegate: self, queue: nil, options: nil)
        }
    }

    // MARK: - Central Manager Control Methods

    func startScanning() {
        let scanOption = [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        centralManager?.scanForPeripherals(withServices: nil, options: scanOption)
        isSearching = true
    }

    func stopScan(){
        centralManager?.stopScan()
        print("# Stop Scan")
        isSearching = false
    }

    func connect(to selectPeripheral: CBPeripheralProtocol) {
        centralManager.connect(selectPeripheral, options: nil)
        stopScan()
    }

    func disconnectPeripheral() {
        guard let connectedPeripheral = connectedPeripheral else { return }
        centralManager.cancelPeripheralConnection(connectedPeripheral)
    }

    // MARK: - Central Manager Delegate Methods

    func didDiscover(_ central: CBCentralManagerProtocol, peripheral: CBPeripheralProtocol, advertisementData: [String : Any], rssi: NSNumber) {
        if rssi.intValue >= 0 { return }
        let peripheralName = advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? nil
        var _name = "NoName"

        if peripheralName != nil {
            _name = String(peripheralName!)
        } else if peripheral.name != nil {
            _name = String(peripheral.name!)
        }

        let foundPeripheral: Peripheral = Peripheral(_peripheral: peripheral,
                                                             _name: _name,
                                                             _advData: advertisementData,
                                                             _rssi: rssi,
                                                             _discoverCount: 0)

        if let index = foundPeripherals.firstIndex(where: { $0.peripheral.identifier.uuidString == peripheral.identifier.uuidString }) {
            if foundPeripherals[index].discoverCount % 50 == 0 {
                foundPeripherals[index].name = _name
                foundPeripherals[index].rssi = rssi.intValue
                foundPeripherals[index].discoverCount += 1
            } else {
                foundPeripherals[index].discoverCount += 1
            }
        } else {
            foundPeripherals.append(foundPeripheral)
            DispatchQueue.main.async { self.isSearching = false }
        }

        guard let userDevice = userDevice else {
            return
        }

        if _name.contains(userDevice.DeviceName) {
            stopScan()
            foundPeripheralCompletion?(foundPeripheral, nil)
        }
    }

    func didConnect(_ central: CBCentralManagerProtocol, peripheral: CBPeripheralProtocol) {
        logger.debug("Connected to peripheral: \(peripheral.name ?? "Unnamed")")
        connectedPeripheral = peripheral
        connectedPeripheral?.delegate = self
        connectionState = .connectedToAdapter
        connectionCompletion?(peripheral, nil)
    }

    func scanForPeripheralAsync(device: DeviceInfo) async throws -> Peripheral? {
        // returns a single peripheral with the specified services
        self.userDevice = device
        let scanOption = [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        isSearching = true
        print("Scanning for: ", device.DeviceName)
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Peripheral, Error>) in
            self.foundPeripheralCompletion = { peripheral, error in
                if let peripheral = peripheral {
                    continuation.resume(returning: peripheral)
                } else if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(throwing: SendMessageError.timeout)
                }
            }
            centralManager?.scanForPeripherals(withServices: [CBUUID(string: device.serviceUUID)], options: scanOption)
        }
    }

    func connectAsync(peripheral: Peripheral) async throws -> CBPeripheralProtocol {
        // ... (peripheral connection logic)
        peripheral.peripheral.delegate = self
        let connectedPeripheral = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CBPeripheralProtocol, Error>) in
            self.connectionCompletion = { peripheral, error in
                if let peripheral = peripheral {
                    continuation.resume(returning: peripheral)
                } else if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(throwing: SendMessageError.timeout)
                }
            }
            connect(to: peripheral.peripheral)
        }
        try await discoverServicesAsync(for: connectedPeripheral)
        return connectedPeripheral
    }

    func discoverServicesAsync(for peripheral: CBPeripheralProtocol) async throws {
        let services = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[CBService], Error>) in
            self.serviceDiscoveryCompletion = { service, error in
                if let service = service {
                    continuation.resume(returning: service)
                } else if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(throwing: SendMessageError.timeout)
                }
            }
            peripheral.discoverServices(nil)
        }

        for service in services {
            try await discoverCharacteristicsAsync(peripheral, for: service)
        }
    }

    func discoverCharacteristicsAsync(_ peripheral: CBPeripheralProtocol, for service: CBService) async throws {
        let _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[CBCharacteristic], Error>) in
            self.characteristicDiscoveryCompletion = { characteristic, error in
                if let characteristic = characteristic {
                    continuation.resume(returning: characteristic)
                } else if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(throwing: SendMessageError.timeout)
                }
            }
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    // MARK: - Peripheral Delegate Methods

    func didDiscoverServices(_ peripheral: CBPeripheralProtocol, error: Error?) {
        if let error = error {
            self.serviceDiscoveryCompletion?(nil, error)
        } else if let services = peripheral.services {
            self.serviceDiscoveryCompletion?(services, nil)
        }
    }

    func didDiscoverCharacteristics(_ peripheral: CBPeripheralProtocol, service: CBService, error: Error?) {
        if let error = error {
            self.characteristicDiscoveryCompletion?(nil, error)
        } else if let characteristics = service.characteristics {
            self.characteristicDiscoveryCompletion?(characteristics, nil)
        }
    }

    func didUpdateState(_ central: CBCentralManagerProtocol) {
        switch central.state {
        case .poweredOn:
            logger.debug("Bluetooth is On.")
            guard let device = connectedPeripheral else {
                return
            }
            connect(to: device)
        case .poweredOff:
            logger.warning("Bluetooth is currently powered off.")
        case .unsupported:
            logger.error("This device does not support Bluetooth Low Energy.")
        case .unauthorized:
            logger.error("This app is not authorized to use Bluetooth Low Energy.")
        case .resetting:
            logger.warning("Bluetooth is resetting.")
        default:
            logger.error("Bluetooth is not powered on.")
            fatalError()
        }
    }

    func didFailToConnect(_ central: CBCentralManagerProtocol, peripheral: CBPeripheralProtocol, error: Error?) {
        logger.error("Failed to connect to peripheral: \(peripheral.name ?? "Unnamed")")
        connectedPeripheral = nil
        disconnectPeripheral()
    }

    func didDisconnect(_ central: CBCentralManagerProtocol, peripheral: CBPeripheralProtocol, error: Error?) {
        logger.warning("Disconnected from peripheral: \(peripheral.name ?? "Unnamed")")
        connectedPeripheral = nil
        connectionState = .notConnected
        resetConfigure()
    }

    func resetConfigure() {
        ecuCharacteristic = nil
        connectedPeripheral = nil
    }

    func didUpdateValue(_ peripheral: CBPeripheralProtocol, characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            logger.error("Error reading characteristic value: \(error.localizedDescription)")
            return
        }

        guard let characteristicValue = characteristic.value else {
            return
        }

        switch characteristic {
        case ecuCharacteristic:
            processReceivedData(characteristicValue, completion: sendMessageCompletion)

        default:
            if let responseString = String(data: characteristicValue, encoding: .utf8) {
                logger.info("\(responseString)")
            } else {
                logger.info("Unknown characteristic: \(characteristic.uuid)")
            }
        }
    }

    func connectionEventDidOccur(_ central: CBCentralManagerProtocol, event: CBConnectionEvent, peripheral: CBPeripheralProtocol) {
        print("Connection event occurred: \(event)")
    }

    // MARK: - Sending Messages

    // TODO: currently can be called multiple times before the first call returns which causes a continuation error
    //       need to figure out how to handle this

    func sendMessageAsync(_ message: String, characteristic: CBCharacteristic? = nil) async throws -> [String] {
        // ... (sending message logic)
        self.ecuCharacteristic = characteristic
        let message = "\(message)\r"
        if debug {
            logger.info("Sending: \(message)")
        }
        guard let connectedPeripheral = self.connectedPeripheral,
              let characteristic = self.ecuCharacteristic,
              let data = message.data(using: .ascii
              ) else {
            logger.error("Error: Missing peripheral or characteristic.")
            throw SendMessageError.missingPeripheralOrCharacteristic
        }

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[String], Error>) in
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
            connectedPeripheral.writeValue(data, for: characteristic, type: .withResponse)
        }
    }

    func processReceivedData(_ data: Data, completion: (([String]?, Error?) -> Void)?) {
        buffer.append(data)

        guard var string = String(data: buffer, encoding: .utf8) else {
            logger.warning("Failed to convert data to a string")
            buffer.removeAll()
            return
        }

        if string.contains(">") {

            string = string
                .replacingOccurrences(of: "\u{00}", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            // Split into lines while removing empty lines
            var lines = string
                .components(separatedBy: .newlines)
                .filter { !$0.isEmpty }

            // remove the last line
            lines.removeLast()
            if debug {
                logger.info("Response: \(lines)")
            }
            completion?(lines, nil)
            buffer.removeAll()
        }
    }
    
    enum SendMessageError: Error {
        case missingPeripheralOrCharacteristic
        case timeout
        case stringConversionFailed
    }
}

extension BLEManager: CBCentralManagerDelegate, CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        didDiscoverServices(peripheral, error: error)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
       didDiscoverCharacteristics(peripheral, service: service, error: error)
     }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        didUpdateValue(peripheral, characteristic: characteristic, error: error)
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        didDiscover(central, peripheral: peripheral, advertisementData: advertisementData, rssi: RSSI)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        didConnect(central, peripheral: peripheral)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        didUpdateState(central)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        didFailToConnect(central, peripheral: peripheral, error: error)
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        didDisconnect(central, peripheral: peripheral, error: error)
    }
}

//    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
//        willRestoreState(central, dict: dict)
//    }
//    func didDiscoverCharacteristics(_ peripheral: CBPeripheralProtocol, service: CBService, error: Error?) {
//        guard let characteristics = service.characteristics else {
//            logger.error("No characteristics found")
//            return
//        }
//
//        for characteristic in characteristics {
//            self.connectedPeripheral = peripheral
//            if characteristic.properties.contains(.write) && characteristic.properties.contains(.read) {
//                let message = "ATZ\r"
//                let data = message.data(using: .ascii)!
//                peripheral.writeValue(data, for: characteristic, type: .withResponse)
//                peripheral.readValue(for: characteristic)
//                let response = characteristic.value
//                if let response = response {
//                    ecuCharacteristic = characteristic
//                    let responseString = String(data: response, encoding: .utf8)
//                    logger.info("response: \(responseString ?? "No Response")")
//                }
//            }
//            switch characteristic.uuid.uuidString {
//            case userDevice?.characteristicUUID:
//                logger.info("ecu \(characteristic)")
//                ecuCharacteristic = characteristic
//                peripheral.setNotifyValue(true, for: characteristic)
////                connectionCompletion?(peripheral)
//                logger.info("Adapter Ready")
//            default:
//                if debug {
//                    logger.info("Unhandled Characteristic UUID: \(characteristic)")
//                }
//                if characteristic.properties.contains(.notify) {
//                    peripheral.setNotifyValue(true, for: characteristic)
//                }
//            }
//        }
//    }
//        [CBCentralManagerOptionRestoreIdentifierKey: BLEManager.RestoreIdentifierKey]

//    func willRestoreState(_ central: CBCentralManagerProtocol, dict: [String : Any]) {
//        if let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] {
//            logger.debug("Restoring \(peripherals.count) peripherals")
//            for peripheral in peripherals {
//                logger.debug("Restoring peripheral: \(peripheral.name ?? "Unnamed")")
//                peripheral.delegate = self
//                connectedPeripheral = peripheral
//                connectionState = .connectedToAdapter
//            }
//        }
//    }
