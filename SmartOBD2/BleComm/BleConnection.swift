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
    let characteristicUUID: String
}

class BLEManager: NSObject, ObservableObject, CBPeripheralProtocolDelegate, CBCentralManagerProtocolDelegate {
    let logger = Logger.bleCom

    // MARK: Properties
    @Published var isSearching: Bool = false
    @Published var connectionState: ConnectionState = .notInitialized
    // BLUETOOTH
    @Published var ecuCharacteristic: CBCharacteristic?
    @Published var connectedPeripheral: Peripheral?
    @Published var foundPeripherals: [Peripheral] = []

    @Published var discoveredServicesAndCharacteristics: [(CBService, [CBCharacteristic])] = []

    private var centralManager: CBCentralManagerProtocol!

    static let RestoreIdentifierKey: String = "OBD2Adapter"

    static let UserDevice: DeviceInfo = DeviceInfo(DeviceName: "Carly", 
                                                   serviceUUID: "FFE0",
                                                   peripheralUUID: "5B6EE3F4-2FCA-CE45-6AE7-8D7390E64D6D",
                                                   characteristicUUID: "FFE1"
    )

    var debug = false

    var buffer = Data()

    var sendMessageCompletion: (([String]?, Error?) -> Void)?
    var connectionCompletion: ((CBPeripheralProtocol) -> Void)?

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

    // MARK: Central Manager Control Methods

    func startScan(services: [CBUUID]) {
        let scanOption = [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        centralManager?.scanForPeripherals(withServices: services, options: scanOption)
        isSearching = true
    }

    func stopScan(){
        centralManager?.stopScan()
        print("# Stop Scan")
        isSearching = false
    }

    func connect(to selectPeripheral: Peripheral) {
        // ... (peripheral connection logic)
        let connectPeripheral = selectPeripheral
        connectedPeripheral = selectPeripheral
        centralManager.connect(connectPeripheral.peripheral, options: nil)
        stopScan()
    }

    func disconnectPeripheral() {
        guard let connectedPeripheral = connectedPeripheral else { return }
        centralManager.cancelPeripheralConnection(connectedPeripheral.peripheral)
    }

    // MARK: Central Manager Delegate Methods

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
    }

    func didConnect(_ central: CBCentralManagerProtocol, peripheral: CBPeripheralProtocol) {
        logger.debug("Connected to peripheral: \(peripheral.name ?? "Unnamed")")
        discoverPeripheralServices(peripheral)
        connectedPeripheral?.peripheral.delegate = self
        connectionCompletion?(peripheral)
        connectionState = .connectedToAdapter
    }

    func didUpdateState(_ central: CBCentralManagerProtocol) {
        switch central.state {
        case .poweredOn:
            logger.debug("Bluetooth is On.")
            guard let device = connectedPeripheral else {
                startScan(services: [CBUUID(string: BLEManager.UserDevice.serviceUUID)])
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

    func willRestoreState(_ central: CBCentralManagerProtocol, dict: [String : Any]) {
        if let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] {
            logger.debug("Restoring \(peripherals.count) peripherals")
            for peripheral in peripherals {
                logger.debug("Restoring peripheral: \(peripheral.name ?? "Unnamed")")
                if isDevicePeripheral(peripheral) {
                    peripheral.delegate = self

                    connectedPeripheral = Peripheral(_peripheral: peripheral,
                                                    _name: peripheral.name ?? "Unnamed",
                                                    _advData: nil,
                                                    _rssi: nil,
                                                    _discoverCount: 0)
                    connectionState = .connectedToAdapter
                }
            }
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
        connectionState = .notInitialized
        resetConfigure()
    }

    func resetConfigure() {
        ecuCharacteristic = nil
        discoveredServicesAndCharacteristics = []
    }

    private func isDevicePeripheral(_ peripheral: CBPeripheral) -> Bool {
        return BLEManager.UserDevice.peripheralUUID == peripheral.identifier.uuidString
    }

    func discoverPeripheralServices(_ peripheral: CBPeripheralProtocol) {
        peripheral.discoverServices(nil)
    }

    func connectAsync(peripheral: Peripheral) async throws -> CBPeripheralProtocol {
        // ... (peripheral connection logic)
        peripheral.peripheral.delegate = self
        connect(to: peripheral)
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CBPeripheralProtocol, Error>) in
            // Set up a timeout timer
            self.connectionCompletion = { peripheral in
                continuation.resume(returning: peripheral)
            }
        }
    }

    // MARK: Peripheral Delegate Methods

    func didDiscoverServices(_ peripheral: CBPeripheralProtocol, error: Error?) {
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

    func didDiscoverCharacteristics(_ peripheral: CBPeripheralProtocol, service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else {
            logger.error("No characteristics found")
            return
        }
        self.discoveredServicesAndCharacteristics.append((service, characteristics))

        for characteristic in characteristics {
            switch characteristic.uuid.uuidString {
            case BLEManager.UserDevice.characteristicUUID:
                logger.info("ecu \(characteristic)")
                ecuCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
                logger.info("Adapter Ready")
            default:
                if debug {
                    logger.info("Unhandled Characteristic UUID: \(characteristic)")
                }
                if characteristic.properties.contains(.notify) {
                    peripheral.setNotifyValue(true, for: characteristic)
                }
            }
        }
    }

    func didUpdateValue(_ peripheral: CBPeripheralProtocol, characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            logger.error("Error reading characteristic value: \(error.localizedDescription)")
            return
        }

        guard let characteristicValue = characteristic.value else {
            return
        }

        switch characteristic.uuid.uuidString {
        case BLEManager.UserDevice.characteristicUUID:
            processReceivedData(characteristicValue, completion: sendMessageCompletion)

        default:
            logger.info("Unknown characteristic: \(characteristic.uuid.uuidString)")
            if let responseString = String(data: characteristicValue, encoding: .utf8) {
                logger.info("\(responseString)")
            } else {
                logger.warning("Invalid data format for characteristic: \(characteristic.uuid.uuidString)")
            }
        }
    }

    func connectionEventDidOccur(_ central: CBCentralManagerProtocol, event: CBConnectionEvent, peripheral: CBPeripheralProtocol) {

    }

    // MARK: Sending Messages

    // TODO: currently can be called multiple times before the first call returns which causes a continuation error
    //       need to figure out how to handle this

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

        connectedPeripheral.peripheral.writeValue(data, for: ecuCharacteristic, type: .withResponse)

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

    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
            willRestoreState(central, dict: dict)
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
