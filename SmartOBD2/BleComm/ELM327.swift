//
//  ELM327.swift
//  SmartOBD2
//
//  Created by kemo konteh on 8/5/23.
//

import Foundation
import CoreBluetooth
import Combine
import OSLog

struct ECUHeader {
    static let ENGINE = "7E0"
}

// Possible setup errors
enum SetupError: Error {
    case invalidResponse
    case noProtocolFound
    case adapterInitFailed
    case timeout
    case peripheralNotFound
    case ignitionOff
    case invalidProtocol
}

enum DataValidationError: Error {
    case oddDataLength
    case invalidDataFormat
    case insufficientDataLength
}

// MARK: - ELM327 Class

class ELM327: ObservableObject {

    // MARK: - Properties
    @Published var statusMessage: String = ""

    let logger = Logger.elmCom

    // Bluetooth UUIDs
    var elmServiceUUID = CBUUID(string: CarlyObd.elmServiceUUID)
    var elmCharactericUUID = CBUUID(string: CarlyObd.elmCharactericUUID)
    // Bluetooth manager
    var bleManager: BLEManager

    // MARK: - Initialization

    init(bleManager: BLEManager) {
        self.bleManager = bleManager
    }

    var obdProtocol: PROTOCOL = .NONE

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

    func okResponse(message: String) async throws -> [String] {
        let response = try await self.bleManager.sendMessageAsync(message)
        if response.contains("OK") {
            return response
        } else {
            logger.error("Invalid response: \(response)")
            throw SetupError.invalidResponse
        }
    }

    func requestDTC() async throws {
        do {
            let response = try await sendMessageAsync("0101")

            await decodeDTC(response: response)
        } catch {
            logger.error("\(error.localizedDescription)")
            throw error
        }
    }

    func decodeDTC(response: [String]) async {
        guard let messages = call(response, idBits: obdProtocol.idBits) else {
            logger.error("could not parse")
            // maybe header is off
            return
        }

        let command = OBDCommand.status
        guard let status = command.decoder.decode(data: messages[0].data) as? Status else {
            return
        }
        if status.MIL {
            logger.info("\(status.dtcCount)")
            // get dtc's
        } else {
            logger.info("no dtc found")
        }
    }

    func setupAdapter(setupOrder: [SetupStep], autoProtocol: Bool = false) async throws -> OBDInfo {
        var obdInfo = OBDInfo()

//        if connectionState != .connectedToAdapter {
//            try await connectToAdapter()
//        }

        try await adapterInitialization(setupOrder: setupOrder)

        try await connectToVehicle(autoProtocol: autoProtocol)

        obdInfo.obdProtocol = obdProtocol
        obdInfo.supportedPIDs = await getSupportedPIDs(obdProtocol)
        try await _ = okResponse(message: "ATH0")

        // Setup Complete will attempt to get the VIN Number
        if let vin = await requestVin() {
            obdInfo.vin = vin
        }
        try await _ = okResponse(message: "ATH1")

        await setHeader(header: ECUHeader.ENGINE)

        return obdInfo
    }

    func requestVin() async -> String? {
        do {
            let vinResponse = try await sendMessageAsync("0902")
            let vin = await decodeVIN(response: vinResponse.joined())
            return vin
        } catch {
            logger.error("\(error.localizedDescription)")
            return nil
        }
    }

    func adapterInitialization(setupOrder: [SetupStep]) async throws {
        do {
            for step in setupOrder {
                switch step {
                case .ATD, .ATL0, .ATE0, .ATH1, .ATAT1, .ATSTFF, .ATH0:
                    _ = try await okResponse(message: step.rawValue)
                case .ATZ:
                    _ = try await sendMessageAsync("ATZ")
                case .ATRV:
                    // get the voltage
                    let voltage = try await sendMessageAsync("ATRV")
                    logger.info("Voltage: \(voltage)")
                case .ATDPN:
                    // Describe current protocol number
                    let protocolNumber = try await sendMessageAsync("ATDPN")
                    self.obdProtocol = PROTOCOL(rawValue: protocolNumber[0]) ?? .protocol9
                default:
                    logger.error("Invalid Setup Step here: \(step.rawValue)")
                }
            }
        } catch {
            logger.error("\(error.localizedDescription)")
            throw SetupError.adapterInitFailed
        }
    }

    func connectToVehicle(autoProtocol: Bool) async throws {
        if autoProtocol {
            guard let _obdProtocol = try await autoProtocolDetection() else {
                logger.error("No protocol found")
                throw SetupError.noProtocolFound
            }
            obdProtocol = _obdProtocol
        } else {
            try await manualProtocolDetection()
        }
    }

    func setHeader(header: String) async {
        do {
            _ = try await okResponse(message: "AT SH " + header + " ")
        } catch {
            logger.error("Set Header ('AT SH %s') did not return 'OK'")
        }
    }

    // MARK: - Protocol Selection

    func autoProtocolDetection() async throws -> PROTOCOL? {
        do {
            _ = try await okResponse(message: "ATSP0")

            try await testProtocol(obdProtocol: obdProtocol)

            let obdProtocolNumber = try await sendMessageAsync("ATDPN")
            guard let obdProtocol = PROTOCOL(rawValue: obdProtocolNumber[0]) else {
                throw SetupError.invalidResponse
            }

            return obdProtocol
        } catch {
            logger.error("\(error.localizedDescription)")
            throw error
        }
    }

    func manualProtocolDetection() async throws {
        do {
            while obdProtocol != .NONE {
                do {
                    try await testProtocol(obdProtocol: obdProtocol)
                    logger.info("Protocol: \(self.obdProtocol.description)")
                    return // Exit the loop if the protocol is found successfully
                } catch {
                    // Other errors are propagated
                    obdProtocol = obdProtocol.nextProtocol()
                }
            }
            // If we reach this point, no protocol was found
            logger.error("No protocol found")
            throw SetupError.noProtocolFound
        } catch {
            logger.error("\(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Protocol Testing

    func testProtocol(obdProtocol: PROTOCOL) async throws {
        do {
            // test protocol by sending 0100 and checking for 41 00 response
            _ = try await okResponse(message: obdProtocol.cmd)

            let r100 = try await sendMessageAsync("0100", withTimeoutSecs: 10)

            if r100.joined().contains("NO DATA") {
                logger.info("car is off")
                throw SetupError.ignitionOff
            }

            guard r100.joined().contains("41 00") else {
                logger.error("Invalid response to 0100")
                throw SetupError.invalidProtocol
            }

            logger.info("Protocol \(obdProtocol.rawValue) found")

            let response = try await sendMessageAsync("0100", withTimeoutSecs: 10)
            guard let messages = call(response, idBits: obdProtocol.idBits) else {
                logger.error("Invalid response to 0100")
                throw SetupError.invalidProtocol
            }

            _ = populateECUMap(messages)
        } catch {
            logger.error("\(error.localizedDescription)")
            throw error
        }
    }

    func populateECUMap(_ messages: [Message]) -> [UInt8: ECUID]? {
        let engineTXID = 0
        let transmissionTXID = 1
        var ecuMap: [UInt8: ECUID] = [:]

        // If there are no messages, return an empty map
        guard !messages.isEmpty else {
            return nil
        }

        // If there is only one message, assume it's from the engine
        if messages.count == 1 {
            ecuMap[messages[0].txID ?? 0] = .engine
            return ecuMap
        }

        // Find the engine and transmission ECU based on TXID
        var foundEngine = false

        for message in messages {
            guard let txID = message.txID else {
                logger.error("parse_frame failed to extract TX_ID")
                continue
            }

            if txID == engineTXID {
                ecuMap[txID] = .engine
                foundEngine = true
            } else if txID == transmissionTXID {
                ecuMap[txID] = .transmission
            }
        }

        // If engine ECU is not found, choose the one with the most bits
        if !foundEngine {
            var bestBits = 0
            var bestTXID: UInt8?

            for message in messages {
                let bits = message.data.bitCount()
                if bits > bestBits {
                    bestBits = bits
                    bestTXID = message.txID
                }
            }

            if let bestTXID = bestTXID {
                ecuMap[bestTXID] = .engine
            }
        }

        // Assign transmission ECU to messages without an ECU assignment
        for message in messages where ecuMap[message.txID ?? 0] == nil {
            ecuMap[message.txID ?? 0] = .transmission
        }

        return ecuMap
    }

    func decodeVIN(response: String) async -> String {
        // Find the index of the occurrence of "49 02"
        guard let prefixIndex = response.range(of: "49 02")?.upperBound else {
            logger.error("Prefix not found in the response")
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
}

struct BatchedResponse {
    private var buffer: Data

    init(response: Data) {
        self.buffer = response
    }

    mutating func getValueForCommand(_ cmd: OBDCommand) -> PidData? {
        if buffer.count < cmd.bytes {
            return nil
        }
        // value is first occurence of cmd.command to cmd.bytes
        let value = buffer.prefix(cmd.bytes)

        print("value ",value.compactMap { String(format: "%02X ", $0) }.joined())

        buffer.removeFirst(cmd.bytes)
        print("Buffer: \(buffer.compactMap { String(format: "%02X ", $0) }.joined())")

        guard let measurement = cmd.decoder.decode(data: value.dropFirst()) else {
            return nil
        }
        print("Measurement: \(String(describing: measurement))")

        return PidData(pid: cmd, value: measurement)
    }
}

extension ELM327 {
    func requestPIDs(_ pids: [OBDCommand]) async -> [PidData]? {
        do {
            let response = try await sendMessageAsync("01" + pids.compactMap { $0.command }.joined())
            guard let messages = call(response, idBits: obdProtocol.idBits) else {
                return nil
            }
            let data = messages[0].data

            var res = BatchedResponse(response: data)

            return pids.compactMap { cmd in res.getValueForCommand(cmd) }
        } catch {
            logger.error("\(error.localizedDescription)")
            return nil
        }
    }

    func decodePIDs(response: [String], pid: OBDCommand) async -> OBDDecodeResult? {
        guard let messages = call(response, idBits: obdProtocol.idBits) else {
            logger.error("could not parse")
            // maybe header is off
            return nil
        }
        if let decodedValue = pid.decoder.decode(data: messages[0].data.dropFirst()) {
            return decodedValue
        } else {
            return nil
        }
    }
}
