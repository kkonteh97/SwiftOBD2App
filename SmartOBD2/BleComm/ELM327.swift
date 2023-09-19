//
//  ELM327.swift
//  SmartOBD2
//
//  Created by kemo konteh on 8/5/23.
//

import Foundation
import CoreBluetooth
import OSLog

<<<<<<< HEAD
struct ECUHeader {
=======
protocol ElmManager {
    func sendMessageAsync(_ message: String,  withTimeoutSecs: TimeInterval) async throws -> [String]
    func setupAdapter(setupOrder: [SetupStep]) async throws -> OBDInfo
}

struct OBDInfo: Codable {
    var vin: String?
    var supportedPIDs: [OBDCommand]?
    var obdProtocol: PROTOCOL = .NONE
}

enum FrameType: UInt8, Codable {
    case SF = 0x00
    case FF = 0x10
    case CF = 0x20
}

enum TxId: UInt8, Codable {
    case engine = 0x00
    case transmission = 0x01
}

//struct Frame: Hashable, Codable {
//    var raw: String
//    var ecuheader: String?
//    var data: [UInt8]
//    var priority: UInt8?
//    var addrMode: UInt8?
//    var txId: TxId?
//    var type: FrameType?
//    var dataLen: UInt16?
//    var pids: [PIDs]?
//    
//}
struct ECU_HEADER {
 // Values for the ECU headers
>>>>>>> main
    static let ENGINE = "7E0"
}

// Possible setup errors
enum SetupError: Error {
    case invalidResponse
    case timeout
    case peripheralNotFound
}

enum DataValidationError: Error {
    case oddDataLength
    case invalidDataFormat
    case insufficientDataLength
}

<<<<<<< HEAD
class ELM327: ObservableObject {

=======
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
    
>>>>>>> main
    // MARK: - Properties

    let logger = Logger.elmCom
    // Bluetooth UUIDs
    var elmServiceUUID = CBUUID(string: CarlyObd.elmServiceUUID)
    var elmCharactericUUID = CBUUID(string: CarlyObd.elmCharactericUUID)

    // Bluetooth manager
    var bleManager: BLEManager
<<<<<<< HEAD
    let singleFrame: UInt8 = 0x00  // single frame
    let firstFrame: UInt8 = 0x10  // first frame of multi-frame message
    let consecutiveFrame: UInt8 = 0x20  // consecutive frame(s) of multi-frame message
    let engineTXID = 0
    let transmissionTXID = 1
    var obdProtocol: PROTOCOL = .NONE

=======
    
>>>>>>> main
    // MARK: - Initialization
    init(bleManager: BLEManager) {
        self.bleManager = bleManager
    }

    // MARK: - Message Sending

    func sendMessageAsync(_ message: String, withTimeoutSecs: TimeInterval = 2) async throws -> [String] {
        do {
            let response: [String] = try await withTimeout(seconds: withTimeoutSecs) {
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

    func setHeader(header: String) async {
        do {
            _ = try await okResponse(message: "AT SH " + header + " ")
        } catch {
            logger.error("Set Header ('AT SH %s') did not return 'OK'")
        }
    }

    func okResponse(message: String) async throws -> [String] {
        let response = try await self.bleManager.sendMessageAsync(message)
        if response.contains("OK") {
            return response
        } else {
            logger.error("Invalid response: \(response)")
            throw SetupError.invalidResponse
        }
    }

    func setupAdapter(setupOrder: [SetupStep], autoProtocol: Bool = true) async throws -> OBDInfo {
        var obdInfo = OBDInfo()
<<<<<<< HEAD

        if bleManager.connectionState != .connectedToAdapter {
            try await connectToAdapter()
        }

        for step in setupOrder {
            do {
                switch step {
                case .ATD, .ATL0, .ATE0, .ATH1, .ATAT1, .ATSTFF:
                    _ = try await okResponse(message: step.rawValue)
                case .ATZ:
                    try await resetAdapterAndRetrieveInfo()

                case .ATRV:
                    // get the voltage
                    let voltage = try await sendMessageAsync("ATRV")
                    logger.info("Voltage: \(voltage)")

                case .ATDPN:
                    // Describe current protocol number
                    let currentProtocol = try await sendMessageAsync("ATDPN")
                    obdProtocol = PROTOCOL(rawValue: currentProtocol[0]) ?? .AUTO
                default:
                    logger.error("Invalid Setup Step")
=======
        
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
                        
                    case .ATDPN:
                        let currentProtocol = try await sendMessageAsync("ATDPN")           // Describe current protocol number
                        
                        obdProtocol = PROTOCOL(rawValue: currentProtocol[0]) ?? .AUTO
                        
                        if let setupStep = SetupStep(rawValue: "ATSP\(currentProtocol[0])") {
                            setupOrderCopy.append(setupStep)                                // append current protocol to setupOrderCopy
                        }
                        
                    case .ATSP0, .ATSP1, .ATSP2, .ATSP3, .ATSP4, .ATSP5, .ATSP6, .ATSP7, .ATSP8, .ATSP9, .ATSPA, .ATSPB, .ATSPC:
                        do {
                            // test the protocol
                            obdInfo.supportedPIDs = try await testProtocol(step: step, obdProtocol: obdProtocol)
                            
                            bleManager.connectionState = .connectedToVehicle
                            
                            obdInfo.obdProtocol = obdProtocol
                            
                            // Turn header off now
                            _ = try await okResponse(message: "ATH0")
                            
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
                            let vin = await decodeVIN(response: vinResponse[0])
                            obdInfo.vin = vin
                        } catch {
                            logger.error("\(error.localizedDescription)")
                        }
                    }
                } catch {
                    throw error
>>>>>>> main
                }
            } catch {
                throw error
            }
        }

        do {
            try await connectToVehicle()
            obdInfo.obdProtocol = obdProtocol
            obdInfo.supportedPIDs = await getSupportedPIDs(obdProtocol)
        } catch {
            logger.error("\(error.localizedDescription)")
        }
<<<<<<< HEAD

        // Setup Complete will attempt to get the VIN Number
        do {
            let vinResponse = try await sendMessageAsync("0902")
            let vin = await decodeVIN(response: vinResponse.joined())
            obdInfo.vin = vin
=======
        return obdInfo
    }
    
    // MARK: - Protocol Testing
    
    func testProtocol(step: SetupStep, obdProtocol: PROTOCOL) async throws -> [OBDCommand] {
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
                
                _ = try await sendMessageAsync("0100")
            }
            
            await setHeader(header: ECU_HEADER.ENGINE)
            
            let response = try await sendMessageAsync("0100")
            
            guard response[0].contains("41 00") else {
                logger.error("Invalid response: \(response)")
                throw SetupError.invalidResponse
            }
            
            
            return await getSupportedPIDs(obdProtocol)
            
>>>>>>> main
        } catch {
            logger.error("\(error.localizedDescription)")
        }
        return obdInfo
    }
<<<<<<< HEAD

//    func autoProtocolDetection() async throws -> PROTOCOL {
//        var protocolNumber: UInt8 = 0
//        var protocol: PROTOCOL = .NONE
//        do {
//            let response = try await sendMessageAsync("ATSP0")
//            logger.info("Auto Protocol Response: \(response)")
//            protocolNumber = UInt8(response[0], radix: 16) ?? 0
//            protocol = PROTOCOL(rawValue: protocolNumber) ?? .AUTO
//        } catch {
//            logger.error("\(error.localizedDescription)")
//        }
//        return protocol
//    }
//

    func connectToVehicle() async throws {
        while obdProtocol != .NONE {
            switch obdProtocol {
            case .protocol1, .protocol2, .protocol3, .protocol4, .protocol5, .protocol6,
                    .protocol7, .protocol8, .protocol9, .protocolA, .protocolB, .protocolC:
                do {
                    _ = try await okResponse(message: obdProtocol.cmd)

                    // test the protocol
                    _ = try await testProtocol(obdProtocol: obdProtocol)
                    bleManager.connectionState = .connectedToVehicle

                    await setHeader(header: ECUHeader.ENGINE)
                } catch {
                    obdProtocol = obdProtocol.nextProtocol()
                    if obdProtocol == .NONE {
                        logger.error("No protocol found")
                        throw SetupError.invalidResponse
                    }
                }
            default:
                logger.error("Invalid Setup Step")
            }
        }
    }

    private func connectToAdapter() async throws {
        bleManager.connectionState = .connecting
        _ = try await self.bleManager.scanAndConnectAsync(services: [self.elmServiceUUID])
        bleManager.connectionState = .connectedToAdapter
    }

    private func resetAdapterAndRetrieveInfo() async throws {
        // Reset command responds with Device Info
        _ = try await sendMessageAsync("ATZ")
    }

    // MARK: - Protocol Testing

    func testProtocol(obdProtocol: PROTOCOL) async throws -> [UInt8: ECU] {

        let response1 = try await sendMessageAsync("0100", withTimeoutSecs: 2)

        guard isHex(response1.joined()) else {
            logger.error("Invalid response: \(response1)")
            throw SetupError.invalidResponse
        }
        let response = try await sendMessageAsync("0100", withTimeoutSecs: 2)

        let messages = call(response, idBits: obdProtocol.idBits)
        for message in messages {
            print(message.frames[0])
=======
    
    func extractDataLength(_ startIndex: Int, _ response: [String]) throws -> Int? {
        guard let lengthHex = UInt8(response[startIndex - 1], radix: 16) else {
            return nil
        }
        // Extract frame data, type, and dataLen
        // Ex.
        //     ||
        // 7E8 06 41 00 BE 7F B8 13
        
        let frameType = FrameType(rawValue: lengthHex & 0xF0)
        
        switch frameType {
        case .SF:
            return Int(lengthHex) & 0x0F
        case .FF:
            guard let secondLengthHex = UInt8(response[startIndex - 2], radix: 16) else {
                throw NSError(domain: "Invalid data format", code: 0, userInfo: nil)
            }
            return Int(lengthHex) + Int(secondLengthHex)
        case .CF:
            return Int(lengthHex)
        default:
            return nil
        }
    }
    
    func getSupportedPIDs(_ obdProtocol: PROTOCOL) async -> [OBDCommand] {
        let pid_getters = Modes.pid_getters
        var supportedPIDsSet: Set<OBDCommand> = Set()

        for pid in pid_getters {
            do {
                let response = try await sendMessageAsync(pid.cmd)[0].components(separatedBy: " ")
                // find first instance of 41 plus command sent, from there we determine the position of everything else
                // Ex.
                //        || ||
                // 7E8 06 41 00 BE 7F B8 13
                guard let startIndex = response.firstIndex(of: "41"), startIndex + 1 < response.count && response[startIndex + 1] == pid.cmd.dropFirst(2) else {
                    return []
                }
                
                do {
                    guard let dataLen = try extractDataLength(startIndex, response),
                          let endIndex = response.index(startIndex, offsetBy: dataLen, limitedBy: response.endIndex) else {
                        // Invalid data length or out-of-bounds, skip this iteration
                        continue
                    }
                    //
                    //             PCI
                    // [  header ] ||       [   data  ]
                    // 00 00 07 E8 06 41 00 BE 7F B8 13 00
                    //                ||                ||
                    //            startIndex        endIndex
                    
                    
                    var data = Array(response[...endIndex]).joined()
                    let ecuData = Array(response[(startIndex + 2)...(endIndex - 1)])

                    
                    if obdProtocol.id_bits == 11 {
                        data = "00000" + data
                    }
                    
                    // Convert ecuData to binary and extract supported PIDs
                    guard let binaryData = hexToBinary(ecuData.joined()) else {
                           continue
                    }
                    let supportedPIDsByECU = extractSupportedPIDs(binaryData)
                    print("pid", supportedPIDsByECU)
                    // Check if the supported PIDs are present in the predefined OBD commands
                    let modeCommands = Modes.mode1
                    // map supportedPIDsByECU to the modeCommands
                    for modeCommand in modeCommands {
                        if supportedPIDsByECU.contains(String(modeCommand.cmd.dropFirst(2))) {
                               supportedPIDsSet.insert(modeCommand) // Add to supported PIDs set
                           }
                       }
                    

                
                } catch {
                    logger.error("\(error.localizedDescription)")
                
                }
            } catch {
                logger.error("\(error.localizedDescription)")
            
            }
>>>>>>> main
        }

        let ecuMap = populateECUMap(messages)
        return ecuMap
    }
<<<<<<< HEAD

    func autoProtocol() {

    }

    func isContiguous(_ indices: [UInt8]) -> Bool {
        var last = indices[0]
        for indice in indices {
            if indice != last + 1 {
                return false
            }
            last = indice
        }
        return true
=======
    

    
    func extractSupportedPIDs(_ binaryData: String) -> [String] {
        return binaryData.enumerated()
            .compactMap { index, bit -> String? in
                if bit == "1" {
                    let pidNumber = String(format: "%02X", index + 1)
                    return pidNumber
                }
                return nil
            }
>>>>>>> main
    }

    func hexToBinary(_ hexString: String) -> String? {
        // Create a scanner to parse the hex string
        let scanner = Scanner(string: hexString)

        // Check if the string starts with "0x" or "0X" and skip it if present
        scanner.charactersToBeSkipped = CharacterSet(charactersIn: "0x")
        var intValue: UInt64 = 0

        // Use the scanner to convert the hex string to an integer
        if scanner.scanHexInt64(&intValue) {
            // Convert the integer to a binary string with leading zeros
            let binaryString = String(intValue, radix: 2)
            let leadingZerosCount = hexString.count * 4 - binaryString.count
            let leadingZeros = String(repeating: "0", count: leadingZerosCount)
            return leadingZeros + binaryString
        }
        // Return nil if the conversion fails
        return nil
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

    @Published var pidsToRequest: [OBDCommand] = []
    @Published var isRequesting = false
    @Published var errorMessage: String?

    func requestPIDs(_ pid: OBDCommand, completion: @escaping (PIDData?) -> Void) async {
        // Ensure you're not already requesting

        do {
            let response = try await sendMessageAsync(pid.cmd)
            let decodedValue = await decodePIDs(response: response[0].components(separatedBy: " "), pid: pid)

            if let measurement = decodedValue {
                // Convert the Measurement<Unit> to a string
                let value = measurement.value
                let unitString = measurement.unit.symbol
                let pidData = PIDData(pid: pid, value: value, unit: unitString)
                completion(pidData) // Pass the result to the completion handler
            } else {
                // Handle the case where response is nil (e.g., no response)
                // You can assign a default or appropriate value here
                completion(nil)
            }
        } catch {
            logger.error("\(error.localizedDescription)")
            completion(nil)
        }
    }

    func decodePIDs(response: [String], pid: OBDCommand) async -> Measurement<Unit>? {
        if let decodedValue = pid.decode(data: response) {
            return decodedValue
        } else {
            return nil
        }
    }

    func populateECUMap(_ messages: [Message]) -> [UInt8: ECU] {
        var ecuMap: [UInt8: ECU] = [:]

        if messages.isEmpty {
            return [:]
        }

        var foundEngine = false
        var bestBits = 0
        var bestTXID: UInt8?

        for message in messages {
            guard let txID = message.txID else {
                print("parse_frame failed to extract TX_ID")
                continue
            }

            if txID == engineTXID {
                ecuMap[txID] = .ENGINE
                foundEngine = true
            } else if txID == transmissionTXID {
                ecuMap[txID] = .TRANSMISSION
            } else {
                let bits = message.data.bitCount()
                if bits > bestBits {
                    bestBits = bits
                    bestTXID = txID
                }
            }
        }

        if !foundEngine, let bestTXID = bestTXID {
            ecuMap[bestTXID] = .ENGINE
        }

        for message in messages where ecuMap[message.txID ?? 0] == nil {
            ecuMap[message.txID ?? 0] = .UNKNOWN
        }

        return ecuMap
    }

}
