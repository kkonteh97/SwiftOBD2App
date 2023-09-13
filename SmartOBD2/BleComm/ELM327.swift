//
//  ELM327.swift
//  SmartOBD2
//
//  Created by kemo konteh on 8/5/23.
//

import Foundation
import CoreBluetooth
import OSLog


protocol ElmManager {
    func sendMessageAsync(_ message: String,  withTimeoutSecs: TimeInterval) async throws -> String
    func setupAdapter(setupOrder: [SetupStep]) async throws -> OBDInfo
}

struct OBDInfo: Codable {
    var vin: String?
    var ecuData: [String: [PIDs]] = [:]
    var obdProtocol: PROTOCOL = .NONE
}

enum ConnectionState {
    case disconnected
    case connecting
    case connectedToAdapter
    case connectedToVehicle
    case failed
}

// Possible setup errors
enum SetupError: Error {
    case invalidResponse
    case timeout
    case peripheralNotFound
}

struct Status {
    var MIL: Bool?
    var DTC_count: UInt8?
    var ignition_type: IgnitionType?
    // Define other properties as needed
}

struct StatusTest {
    var name: String
    var available: Bool
    var complete: Bool

    init(name: String = "", available: Bool = false, complete: Bool = false) {
        self.name = name
        self.available = available
        self.complete = complete
    }

    var description: String {
        let a = available ? "Available" : "Unavailable"
        let c = complete ? "Complete" : "Incomplete"
        return "Test \(name): \(a), \(c)"
    }
}


enum IgnitionType: Int {
    case spark = 0
    case compression = 1
}


class ELM327: ObservableObject, ElmManager {
    
    // MARK: - Properties
    
    let logger = Logger.elmCom
    
    // Bluetooth UUIDs
    var BLE_ELM_SERVICE_UUID = CBUUID(string: CarlyObd.BLE_ELM_SERVICE_UUID)
    var BLE_ELM_CHARACTERISTIC_UUID = CBUUID(string: CarlyObd.BLE_ELM_CHARACTERISTIC_UUID)
    
    // Bluetooth manager
    var bleManager: BLEManager
    
    // MARK: - Initialization
    init(bleManager: BLEManager) {
        BLE_ELM_SERVICE_UUID = CBUUID(string: CarlyObd.BLE_ELM_SERVICE_UUID)
        BLE_ELM_CHARACTERISTIC_UUID = CBUUID(string: CarlyObd.BLE_ELM_CHARACTERISTIC_UUID)
        
        // Configure the BLEManager instance with the appropriate UUIDs
        self.bleManager = bleManager
    }
    
    
    // MARK: - Message Sending
    
    // Send a message asynchronously
    func sendMessageAsync(_ message: String, withTimeoutSecs: TimeInterval = 2) async throws -> String  {
        do {
            let response: String = try await withTimeout(seconds: withTimeoutSecs) {
                let res = try await self.bleManager.sendMessageAsync(message)
                return res
            }
            return response
        } catch {
            logger.error("Error: \(error.localizedDescription)")
            throw SetupError.timeout
        }
    }
    
    
    // MARK: - Setup Steps
    
    
    func okResponse(message: String) async throws -> String {
        /*
         Handle responses with ok
         Commands thats only respond with ok are processed here
         */
        let response = try await self.bleManager.sendMessageAsync(message)
        if response.contains("OK") {
            return response
        } else {
            logger.error("Invalid response: \(response)")
            throw SetupError.invalidResponse
        }
    }
    
    // want to return vin if available, header status, echo status and ecudata
    
    func setupAdapter(setupOrder: [SetupStep]) async throws -> OBDInfo {
        /*
         Perform the setup process
         
         */
        var obdProtocol: PROTOCOL = .NONE

        var obdInfo = OBDInfo()
        
        do {
            if bleManager.connectionState != .connectedToAdapter {
                bleManager.connectionState = .connecting
                let _ = try await withTimeout(seconds: 30) {
                    let peripheral = try await self.bleManager.scanAndConnectAsync(services: [self.BLE_ELM_SERVICE_UUID])
                    return peripheral
                }
                bleManager.connectionState = .connectedToAdapter
            }
            var setupOrderCopy = setupOrder
            var currentIndex = 0
            
            while currentIndex < setupOrderCopy.count {
                let step = setupOrderCopy[currentIndex]
                do {
                    switch step {
                    case .ATD, .ATL0, .ATE0, .ATH1, .ATAT1, .ATSTFF:
                        _ = try await okResponse(message: step.rawValue)
                        
                    case .ATZ:
                        _ = try await sendMessageAsync("ATZ")                               // reset command Responds with Device Info
                        
                    case .ATRV:
                        let voltage = try await sendMessageAsync("ATRV")                    // get the voltage
                        // make sure car is on
                        logger.info("Voltage: \(voltage)")
                    // connection to adapted established at this point
                        
                    case .ATDPN:
                        let currentProtocol = try await sendMessageAsync("ATDPN")           // Describe current protocol number
                        obdProtocol = PROTOCOL(rawValue: currentProtocol) ?? .AUTO
                        
                        if let setupStep = SetupStep(rawValue: "ATSP\(currentProtocol)") {
                            setupOrderCopy.append(setupStep)                                // append current protocol to setupOrderCopy
                        }
                        
                    case .ATSP0, .ATSP1, .ATSP2, .ATSP3, .ATSP4, .ATSP5, .ATSP6, .ATSP7, .ATSP8, .ATSP9, .ATSPA, .ATSPB, .ATSPC:
                        do {
                            // test the protocol
                            obdInfo.ecuData = try await testProtocol(step: step, obdProtocol: obdProtocol)
                            obdInfo.obdProtocol = obdProtocol
                            
                            if let setupStep = SetupStep(rawValue: "AT0902") {
                                setupOrderCopy.append(setupStep)
                            }
                            
                            logger.info("Setup Completed successfulleh")
                            
                        } catch {
                            obdProtocol = obdProtocol.nextProtocol()
                            
                            if obdProtocol == .NONE {
                                logger.error("No more protocols to try")
                                throw error
                            }
                            
                            if let setupStep = SetupStep(rawValue: "ATSP\(obdProtocol.rawValue)") {
                                setupOrderCopy.append(setupStep)                            // append next protocol fi setupOrderCopy
                            }
                        }
                        
                        // Setup Complete will attempt to get the VIN Number
                    case .AT0902:
                        do {
                            let vinResponse = try await sendMessageAsync("0902")             // Try to get VIN
                            let vin = await decodeVIN(response: vinResponse)
                            obdInfo.vin = vin
                        } catch {
                            logger.error("\(error.localizedDescription)")
                        }
                    }
                } catch {
                    throw error
                }
                currentIndex += 1
            }
        } catch {
            throw SetupError.peripheralNotFound
        }
        return obdInfo
    }
    
    // MARK: - Protocol Testing
    
    
    
    func testProtocol(step: SetupStep, obdProtocol: PROTOCOL) async throws -> [String: [PIDs]] {
        do {
            // test protocol by sending 0100 and checking for 41 00 response
            /*
             while we here might as well get the supported pids
             */
            _ = try await okResponse(message: step.rawValue)
        
            
            let firstResponse = try await sendMessageAsync("0100")
            if firstResponse.contains("searching") {
                // wait a bit and try again
                sleep(5)
                let _ = try await sendMessageAsync("0100")
            }
            
            
            let response = try await sendMessageAsync("0100")
            guard response.contains("41 00") else {
                logger.error("Invalid response: \(response)")
                throw SetupError.invalidResponse
            }
            var responseArray = response.components(separatedBy: " ")
            let ecuData = await getECUs(&responseArray)
            
            // Turn header off now
            _ = try await okResponse(message: "ATH0")

            return ecuData
            
        } catch {
            throw error
        }
    }
    
    func getECUs(_ response: inout [String]) async -> [String: [PIDs]] {
        var ecuHeaders: [String: [PIDs]] = [:]

        while let startIndex = response.firstIndex(of: "41"), startIndex + 1 < response.count && response[startIndex + 1] == "00" {
            if let length = Int(response[startIndex - 1], radix: 16) {
                let endIndex = startIndex + length
                if endIndex < response.count {
                    let data = Array(response[...endIndex])
                    let ecuHeader = Array(data[..<(startIndex - 1)])
                    let ecuData = Array(data[(startIndex + 2)...])
                    let supportedPIDs = await getSupportedPIDs(ecuHeader, ecuData)
                    ecuHeaders[ecuHeader.joined()] = supportedPIDs
                    // Remove the processed segments
                    response.removeSubrange(...endIndex)
                }
            }
        }

        return ecuHeaders
    }
    
    func getSupportedPIDs(_ header: [String], _ data: [String]) async -> [PIDs] {
        do {
            _ = try await okResponse(message: "AT CRA\(header.joined())")
        } catch {
            logger.error("Error setting header: \(error.localizedDescription)")
            return []
        
        }
        // filter 55 out
        let bytes = data
            .filter { $0 != "55" }
            .compactMap { UInt8(String($0), radix: 16) }
        
        // Convert each byte to binary and join them together
        let binaryData = bytes.flatMap { Array(String($0, radix: 2).leftPadding(toLength: 8, withPad: "0")) }
        
        // Define the PID numbers based on the binary data
        let supportedPIDs = binaryData.enumerated()
            .compactMap { index, bit -> String? in
                if bit == "1" {
                    let pidNumber = String(format: "%02X", index + 1)
                    return pidNumber
                }
                return nil
                
            }
        
        // remove nils
        let supportedPIDsByECU = supportedPIDs.map { pid in
            PIDs(rawValue: pid)
        }
        
        print("Supported PIDs: \(supportedPIDsByECU)")
        return supportedPIDsByECU
            .map { $0 }
            .compactMap { $0 }
    }
    
    // MARK: - Decoding VIN
    
    func decodeVIN(response: String) async -> String {
        // Find the index of the occurrence of "49 02"
        guard let prefixIndex = response.range(of: "49 02")?.upperBound else {
            print("Prefix not found in the response")
            return ""
        }
        // Extract the VIN hex string after "49 02"
        let vinHexString = response[prefixIndex...]
            .split(separator: " ")
            .joined() // Remove spaces
        
        // Convert the hex string to ASCII characters
        var asciiString = ""
        var hex = vinHexString
        while !hex.isEmpty {
            let startIndex = hex.startIndex
            let endIndex = hex.index(startIndex, offsetBy: 2)
            
            if let hexValue = UInt8(hex[startIndex..<endIndex], radix: 16) {
                let unicodeScalar = UnicodeScalar(hexValue)
                asciiString.append(Character(unicodeScalar))
            } else {
                logger.error("Error converting hex to UInt8")
            }
            
            hex.removeFirst(2)
        }
        
        // Remove non-alphanumeric characters from the VIN
        let vinNumber = asciiString.replacingOccurrences(
            of: "[^a-zA-Z0-9]",
            with: "",
            options: .regularExpression
        )
        // getvininfo
        return vinNumber
    }
    
    // MARK: - Request PIDs
    
    func requestPIDs(pids: [PIDs]) async throws {
        for pid in pids {
            do {
                let response = try await sendMessageAsync("01\(pid.rawValue)")
                let _ = await decodePIDs(response: response, pid: pid)
            } catch {
                logger.error("\(error.localizedDescription)")
            }
        }
    }
    
    func hexStringToInt(_ hexString: String) -> Int? {
        return Int(hexString, radix: 16)
    }
    
    func decodePID01(data: String) -> Status {
        // Monitor status since DTCs cleared
        // bit encode
        var output = Status()

        guard let value = hexStringToInt(data) else { return output }
        let binary = String(value, radix: 2).leftPadding(toLength: 8, withPad: "0")
        output.MIL = binary[binary.startIndex] == "1"
        output.DTC_count = UInt8(String(binary[binary.index(binary.startIndex, offsetBy: 1)])) ?? 0
        output.ignition_type = binary[binary.index(binary.startIndex, offsetBy: 2)] == "1" ? .spark : .compression
        return output
    }
    
//    func parseDTC(_ bytes: [UInt8]) -> (String, String)? {
//        // Check validity (also ignores padding that may be present)
//        if bytes.count != 2 || bytes == [0, 0] {
//            return nil
//        }
//
//        // DTC Format:
//        // - Bits 7-6 (Byte 1): DTC Type (P, C, B, U)
//        // - Bits 5-4 (Byte 1): High-order bits of DTC
//        // - Bits 3-0 (Byte 2): Low-order bits of DTC
//
//        let dtcType: Character = ["P", "C", "B", "U"][Int(bytes[0] >> 6)]
//        let dtcHighBits: Int = Int((bytes[0] >> 4) & 0b0011)
//        let dtcLowBits: Int = Int(bytes[1] & 0b1111)
//
//        let dtc = "\(dtcType)\(dtcHighBits)\(dtcLowBits)"
//
//        // Pull a description if available
//        let description = DTC[dtc] ?? ""
//
//        return (dtc, description)
//    }
    
    func decodePID02(data: String) -> Double? {
        // Freeze DTC
        guard let value = hexStringToInt(data) else { return nil }
        return Double(value)
    }
    


    func decodePID04(data: String) -> Double? {
        // engine load
        guard let value = hexStringToInt(data) else { return nil }
        return Double(value) / 2.55
    }

    func decodePID05(data: String) -> Int? {
        return hexStringToInt(data).map { $0 - 40 }
    }

    func decodeFuelTrim(data: String) -> Double? {
        guard let value = hexStringToInt(data) else { return nil }
        let fuelTrim = Double(value) * (100.0 / 128.0) - 100.0
        return fuelTrim
    }

    func decodePIDs(response: String, pid: PIDs) async -> String {
        let decodeFunctions: [String: (String) -> Any?] = [
                PIDs.pid04.rawValue: decodePID04,
                PIDs.pid05.rawValue: decodePID05,
                PIDs.pid06.rawValue: decodeFuelTrim,
                PIDs.pid07.rawValue: decodeFuelTrim,
                PIDs.pid08.rawValue: decodeFuelTrim
            ]
        
        guard let decodeFunction = decodeFunctions[pid.rawValue] else {
            return ""
        }
        
        let response = response
            .split(separator: " ")
            .joined() // Remove spaces
        
        let decodedValue = decodeFunction(response)

        return "\(decodedValue ?? "")"
    }
}










