//
//  bleConnection.swift
//  Obd2Scanner
//
//  Created by kemo konteh on 8/3/23.
//

import Foundation
import CoreBluetooth


extension String {
    func leftPadding(toLength: Int, withPad character: Character) -> String {
        let paddingAmount = max(0, toLength - count)
        let padding = String(repeating: character, count: paddingAmount)
        return padding + self
    }
}




class BLEManager: NSObject, CBPeripheralDelegate {
    let BLE_ELM_SERVICE_UUID: CBUUID
    let BLE_ELM_CHARACTERISTIC_UUID: CBUUID
    private var centralManager: CBCentralManager?
    var linesToParse = [String]()
    var adapterReady = false
    
    func logMessage(_ message: String) {
        print(message)
        // Update a text view or label in the UI if needed
        
    }
    
    init(serviceUUID: CBUUID, characteristicUUID: CBUUID) {
            self.BLE_ELM_SERVICE_UUID = serviceUUID
            self.BLE_ELM_CHARACTERISTIC_UUID = characteristicUUID
            super.init()
            centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        logMessage("Connected to peripheral: \(peripheral.name ?? "Unnamed")")
        connectedPeripheral = peripheral
        peripheral.delegate = self // Set the delegate of the connected peripheral
        self.connected = true
        peripheral.discoverServices(nil) // Start discovering all services of the connected peripheral
    }
    
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            // Scan for peripherals if BLE is turned on
            logMessage("Bluetooth is On.")
            self.centralManager?.scanForPeripherals(withServices: [BLE_ELM_SERVICE_UUID], options: nil)
            
        case .poweredOff:
            logMessage("Bluetooth is currently powered off.")
            
        case .resetting:
            logMessage("Bluetooth is resetting.")
        default:
            fatalError()
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Error discovering services: \(error.localizedDescription)")
            return
        }
        
        
        if let services = peripheral.services {
            for service in services {
                if service.uuid == BLE_ELM_SERVICE_UUID {
                    logMessage("OBD2 Service: \(service.uuid)")
                    peripheral.discoverCharacteristics(nil, for: service)
                } else {
                    logMessage("Found Service: \(service)")
                }
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
            
            if let name = peripheral.name {
                if name.contains("Carly") {
                    logMessage("Found Carly Adapter")
                    self.centralManager?.stopScan()
                    connectedPeripheral = peripheral
                    self.centralManager?.connect(peripheral, options: nil)
                }
            }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else {
            print("No characteristics found")
            return
        }
        for characteristic in characteristics {
            if characteristic.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: characteristic)
            }
            switch characteristic.uuid {
            case BLE_ELM_CHARACTERISTIC_UUID:
                ecuCharacteristic = characteristic
                logMessage("Found ECU Characteristic: \(characteristic.uuid)")
                peripheral.setNotifyValue(true, for: characteristic)
                self.adapterReady = true
                logMessage("Adapter Ready")
            default:
                logMessage("Unhandled Characteristic UUID: \(characteristic.uuid)")
                if characteristic.properties.contains(.notify) {
                    peripheral.setNotifyValue(true, for: characteristic)
                    
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            logMessage("Error reading characteristic value: \(error.localizedDescription)")
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
                logMessage("Manufacturer: \(responseString))")
            }
        case "2A26":
            if let response = characteristic.value {
                guard let responseString = String(data: response, encoding: .utf8) else {
                    print("Invalid data format")
                    return
                }
                logMessage("Manufacturer: \(responseString))")
            }
            
        default:
            logMessage("Unknown characteristic")
        }
    }
    
    func sendMessageAsync(message: String) async throws -> String {
        
        let message = "\(message)\r"
        logMessage("Sending: \(message)")
        
        guard let connectedPeripheral = self.connectedPeripheral,
              let ecuCharacteristic = self.ecuCharacteristic,
              let data = message.data(using: .ascii) else {
            logMessage("Error: Missing peripheral or characteristic.")
            throw SendMessageError.missingPeripheralOrCharacteristic
        }
                
        do {
            let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
                self.sendMessageCompletion = { response, error in
                    if let _ = error {
                        continuation.resume(throwing: SendMessageError.timeout)
                    } else {
                        continuation.resume(returning: response)
                    }
                }
                connectedPeripheral.writeValue(data, for: ecuCharacteristic, type: .withResponse)
            }
            return result
        } catch {
            throw error
        }
    }
    
    
    func handleResponse(completion: ((String, String) -> Void)?) {
        logMessage(linesToParse.joined(separator: " "))
        let strippedResponse = linesToParse.map { $0.replacingOccurrences(of: ">", with: "") }.joined()
        print("Response: ",strippedResponse)
        sendMessageCompletion?(strippedResponse, nil)

        self.timeoutTimer?.invalidate()
        linesToParse.removeAll()
    }
    
    
    func processReceivedData(_ data: Data, completion: ((String, String) -> Void)?) {
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
  
    
    
    
    var readyToSend = true
    @Published var currentSetupStepReady = true
    @Published var VIN: String = ""
    @Published var carMake: String = ""
    @Published var carModel: String = ""
    @Published var carYear: String = ""
    @Published var carCylinders: String = ""
    var craFilter: String = ""
    
    @Published var setupInProgress = false
    var setupTimer: Timer?
    fileprivate var numberOfDTCs: Int = 0
    
    
    var currentDTCs: [String] = []
    var requestingDTCs: Bool = false
    var currentGetDTCsQueryReady = false
    
    var getDTCsTimer: Timer?
    var pidTimer: Timer?
        
    //ELM327 PROTOCOL
    var obdProtocol: ELM327.PROTOCOL = .NONE //Will be determined by the setup
    var currentQuery = ELM327.QUERY.Q_ATD
    var setupStatus = ELM327.QUERY.SETUP_STEP.send_ATD
    var getDTCsStatus: ELM327.QUERY.GET_DTCS_STEP = .none
    
    //PARSING
    fileprivate let parser = OBDParser.sharedInstance
    
    //BLUETOOTH
    @Published var connectedPeripheral: CBPeripheral?
    @Published var characteristicsFound: [CBCharacteristic] = []
    @Published var peripherals: [CBPeripheral] = []
    @Published var ecuCharacteristic: CBCharacteristic?
    
    @Published var connected: Bool = false
    @Published var initialized: Bool = false
    
    
    @Published var history: [String] = []
    
    @Published var supportedPIDsByECU: [ELM327.PIDs?] = []
    
    
    
    @Published var pidDescriptions: [String] = []
    
    var timeoutTimer: Timer?
    var requestingPids: Bool = false
    var PIDsReady: Bool = false
    var isProcessingRequest: Bool = false
        
    var sendMessageCompletion: ((String, String?) -> Void)?
    var currentPIDGroupIndex = 0

    
    
    
    
    enum SendMessageError: Error {
        case missingPeripheralOrCharacteristic
        case timeout
    }
    
    func sendMessage(_ message: String, logMessage: String = "Sending message", timeout: TimeInterval = 5.0, completion: @escaping (String, String?) -> Void) {
        let message = "\(message)\r"
        print("Sending: \(message)")
        
        guard let connectedPeripheral = self.connectedPeripheral,
              let ecuCharacteristic = self.ecuCharacteristic,
              let data = message.data(using: .ascii) else {
            print("Error: Missing peripheral or characteristic.")
            completion("Error: Missing peripheral or characteristic.", nil)
            return
        }
        
        // Store the sent message and start a timer if needed
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false) { _ in
            // Handle timeout
            print("Error: Message sending timed out.")
            self.sendMessageCompletion?("Timeout", nil)
            self.timeoutTimer?.invalidate()
        }
        // Store the completion handler
        sendMessageCompletion = completion
        
        // Store the sent message and start a timer
        connectedPeripheral.writeValue(data, for: ecuCharacteristic, type: .withResponse)
    }
    
    

    
    func requestPids() {
        
        if requestingPids {
            return
        }
        self.requestingPids = true

        self.pidTimer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(setupTimedPIDQueries), userInfo: nil, repeats: true)
    }
    
    
    @objc func setupTimedPIDQueries() async {
        guard readyToSend else {
                return
            }
        let pidsGroups = supportedPIDsByECU.chunked(into: 6)
        
        // Calculate the current group index
        let currentIndex = currentPIDGroupIndex % pidsGroups.count
        let group = pidsGroups[currentIndex]
        
        
        guard !isProcessingRequest else {
                return
        }
        
        let _ = group.compactMap { $0?.rawValue }.joined(separator: " ")
//        let cmd = "01\(pidsStr)"
        
        if isProcessingRequest {
            return
        }
        
        self.isProcessingRequest = true
//        sendMessage(cmd, logMessage: "Sending PID request") { message, response in
//            if let responseCopy = response?.components(separatedBy: " ") {
//                guard let indexOf41 = responseCopy.firstIndex(of: "41") else {
//                    return
//                }
//                var responseArray = Array(responseCopy[(indexOf41 + 1)...])
//                var pidcmdsCopy = String(cmd.dropFirst(2)).components(separatedBy: " ")
//
//                self.extractPIDs(pidcmds: &pidcmdsCopy, response: &responseArray)
//            }
//            
//        }
        // Increment the group index for the next cycle
        currentPIDGroupIndex += 1
        }
    
    
    
    
    func discoverDescriptors(peripheral: CBPeripheral, characteristic: CBCharacteristic) {
        peripheral.discoverDescriptors(for: characteristic)
    }
    
    
    
    
}



extension BLEManager: CBCentralManagerDelegate {
   
    
   
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        logMessage("Failed to connect to peripheral: \(peripheral.name ?? "Unnamed")")
        connectedPeripheral = nil
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        self.connected = false
        self.initialized = false
        logMessage("Disconnected from peripheral: \(peripheral.name ?? "Unnamed")")
    }
    
    func connect(to peripheral: CBPeripheral) {
        centralManager?.connect(peripheral, options: nil)
    }
    
}
