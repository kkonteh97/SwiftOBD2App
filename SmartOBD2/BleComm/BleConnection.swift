//
//  bleConnection.swift
//  Obd2Scanner
//
//  Created by kemo konteh on 8/3/23.
//

import Foundation
import CoreBluetooth
import OSLog

enum ConnectionState {
    case notInitialized
    case connecting
    case connectedToAdapter
    case connectedToVehicle
    case failed
    case initialized

    var isConnected: Bool {
            switch self {
            case .notInitialized, .connecting, .failed:
                return false
            case  .connectedToAdapter, .connectedToVehicle, .initialized:
                return true
            }
    }

    var description: String {
        switch self {
        case .notInitialized:
            return "Not Initialized"
        case .connecting:
            return "Connecting"
        case .connectedToAdapter:
            return "Connected to Adapter"
        case .connectedToVehicle:
            return "Connected to Vehicle"
        case .failed:
            return "Failed"
        case .initialized:
            return "Initialized"
        }
    }
}


struct DeviceInfo {
    let DeviceName: String
    let serviceUUID: String
    let peripheralUUID: String
}

class BLEManager: NSObject, CBPeripheralDelegate, ObservableObject, CBCentralManagerDelegate {
    let logger = Logger.bleCom

    // MARK: Properties
    @Published var isSearching: Bool = false
    @Published var connectionState: ConnectionState = .notInitialized
    // BLUETOOTH
    @Published var ecuCharacteristic: CBCharacteristic?
    @Published var connectedPeripheral: CBPeripheral?
    @Published var foundPeripherals: [CBPeripheral] = []
    
    @Published var discoveredServicesAndCharacteristics: [(CBService, [CBCharacteristic])] = []

    private var centralManager: CBCentralManager!

    static let RestoreIdentifierKey: String = "CarlyOBD2"
    static let UserDevice: [DeviceInfo] = [
        DeviceInfo(DeviceName: "Carly", serviceUUID: "FFE0", peripheralUUID: "5B6EE3F4-2FCA-CE45-6AE7-8D7390E64D6D")
    ]


    var linesToParse = [String]()
    var adapterReady = false
    var debug = true

    var buffer = Data()

    var sendMessageCompletion: (([String]?, Error?) -> Void)?
    var connectionCompletion: ((CBPeripheral) -> Void)?

    // MARK: Initialization

    override init() {
        super.init()
        #if targetEnvironment(simulator)
        centralManager = CBCentralManagerMock(delegate: self, queue: nil)
        #else
        centralManager = CBCentralManager(delegate: self,
                                          queue: nil,
                                          options: [CBCentralManagerOptionRestoreIdentifierKey: BLEManager.RestoreIdentifierKey])
        #endif
    }

    // MARK: Central Manager Delegate Methods

    func startScan(service: String) {
        let scanOption = [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        centralManager?.scanForPeripherals(withServices: [CBUUID(string: service)], options: scanOption)
        isSearching = true
    }

    func stopScan(){
            disconnectPeripheral()
            centralManager?.stopScan()
            print("# Stop Scan")
            isSearching = false
    }

    func connect(to peripheral: CBPeripheral) {
        // ... (peripheral connection logic)
        centralManager?.connect(peripheral, options: nil)
        connectedPeripheral = peripheral
        connectedPeripheral?.delegate = self
    }

    func disconnectPeripheral() {
            guard let connectedPeripheral = connectedPeripheral else { return }
            centralManager.cancelPeripheralConnection(connectedPeripheral)
    }

    // MARK: Peripheral Delegate Methods

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber) {
            if !foundPeripherals.contains(where: { $0.identifier == peripheral.identifier }) {
                foundPeripherals.append(peripheral)
                logger.debug("Found \(peripheral.name ?? "Unknown")")
            }

            if isDevicePeripheral(peripheral) {
                stopScan()
                connect(to: peripheral)
        }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            // Scan for peripherals if BLE is turned on
            logger.debug("Bluetooth is On.")
            guard let device = connectedPeripheral else {
                startScan(service: BLEManager.UserDevice[0].serviceUUID)
                return
            }
            connectionState = .connecting
            connect(to: device)

        case .poweredOff:
            logger.warning("Bluetooth is currently powered off.")
            connectionState = .notInitialized
        case .unsupported:
            logger.error("This device does not support Bluetooth Low Energy.")
            connectionState = .failed
        case .unauthorized:
            logger.error("This app is not authorized to use Bluetooth Low Energy.")
            connectionState = .failed
        case .resetting:
            logger.warning("Bluetooth is resetting.")
        default:
            logger.error("Bluetooth is not powered on.")
            fatalError()
        }
    }

    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        if let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] {
            logger.debug("Restoring \(peripherals.count) peripherals")
            for peripheral in peripherals {
                logger.debug("Restoring peripheral: \(peripheral.name ?? "Unnamed")")
                foundPeripherals.append(peripheral)
                connectionState = .connectedToAdapter
                connectedPeripheral = peripheral
                connectedPeripheral?.delegate = self
            }
        }
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        logger.error("Failed to connect to peripheral: \(peripheral.name ?? "Unnamed")")
        connectedPeripheral = nil
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        logger.warning("Disconnected from peripheral: \(peripheral.name ?? "Unnamed")")
        connectedPeripheral = nil
        connectionState = .notInitialized
    }

    private func isDevicePeripheral(_ peripheral: CBPeripheral) -> Bool {
        return BLEManager.UserDevice.contains { $0.peripheralUUID == peripheral.identifier.uuidString }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        logger.debug("Connected to peripheral: \(peripheral.name ?? "Unnamed")")
        discoverPeripheralServices(peripheral)
        connectionState = .connectedToAdapter
    }

    private func discoverPeripheralServices(_ peripheral: CBPeripheral) {
        peripheral.discoverServices(nil)
    }

    func connectAsync(peripheral: CBPeripheral) async throws -> CBPeripheral {
        // ... (peripheral connection logic)
        connect(to: peripheral)
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CBPeripheral, Error>) in
            // Set up a timeout timer
            self.connectionCompletion = { peripheral in
                continuation.resume(returning: peripheral)
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
                if debug {
                    logger.info("Unhandled Characteristic UUID: \(characteristic.uuid)")
                }
                if characteristic.properties.contains(.notify) {
                    peripheral.setNotifyValue(true, for: characteristic)

                }
            }
        }
    }

    // MARK: Sending Messages

    func sendMessageAsync(_ message: String) async throws -> [String] {
        // ... (sending message logic)
        let message = "\(message)\r"
        if debug {
            logger.info("Sending: \(message)")
        }

        guard let connectedPeripheral = self.connectedPeripheral,
              let ecuCharacteristic = self.ecuCharacteristic,
              let data = message.data(using: .ascii
              ) else {
            logger.error("Error: Missing peripheral or characteristic.")
            throw SendMessageError.missingPeripheralOrCharacteristic
        }

        connectedPeripheral.writeValue(data, for: ecuCharacteristic, type: .withResponse)

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
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            logger.error("Error reading characteristic value: \(error.localizedDescription)")
            return
        }

        guard let characteristicValue = characteristic.value else {
            return
        }

        switch characteristic.uuid.uuidString {
        case "FFE1":
            processReceivedData(characteristicValue, completion: sendMessageCompletion)

        case "F000FFC1-0451-4000-B000-000000000000", "2A24", "2A26":
            if let responseString = String(data: characteristicValue, encoding: .utf8) {
                logger.info("Manufacturer: \(responseString)")
            } else {
                logger.warning("Invalid data format for characteristic: \(characteristic.uuid.uuidString)")
            }

        default:
            logger.info("Unknown characteristic: \(characteristic.uuid.uuidString)")
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
