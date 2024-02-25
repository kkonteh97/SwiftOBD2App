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
    case noECUCharacteristic
    case invalidResponse(message: String)
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

func decodeToStatus(_ result: OBDDecodeResult) -> Status? {
    switch result {
    case .statusResult(let value):
        return value
    default:
        return nil
    }
}

final class ELM327 {
    // MARK: - Properties
    let logger = Logger.elmCom

    // Bluetooth manager
    private let bleManager: BLEManager

    var obdProtocol: PROTOCOL = .NONE

    init(bleManager: BLEManager) {
        self.bleManager = bleManager
    }

    // MARK: - Adapter and Vehicle Setup
    func setupVehicle(obdInfo: inout OBDInfo) async throws {
        var obdProtocol: PROTOCOL?

        if let desiredProtocol = obdInfo.obdProtocol {
            do {
                obdProtocol = try await manualProtocolDetection(desiredProtocol: desiredProtocol)
            } catch {
                obdProtocol = nil // Fallback to autoProtocol
            }
        }

        if obdProtocol == nil {
            obdProtocol = try await connectToVehicle(autoProtocol: true)
        }

        guard let obdProtocol = obdProtocol else {
            throw SetupError.noProtocolFound
        }

        self.obdProtocol = obdProtocol
        obdInfo.obdProtocol = obdProtocol
        if obdInfo.vin == nil {
            obdInfo.vin = await requestVin()
        }
        try await setHeader(header: ECUHeader.ENGINE)
    }

    func connectToVehicle(autoProtocol: Bool) async throws -> PROTOCOL? {
        if autoProtocol {
            guard let obdProtocol = try await autoProtocolDetection() else {
                logger.error("No protocol found")
                throw SetupError.noProtocolFound
            }
            return obdProtocol
        } else {
            guard let obdProtocol = try await manualProtocolDetection(desiredProtocol: nil) else {
                logger.error("No protocol found")
                throw SetupError.noProtocolFound
            }
            return obdProtocol
        }
    }

    // MARK: - Protocol Selection

    private func autoProtocolDetection() async throws -> PROTOCOL? {
        _ = try await okResponse(message: "ATSP0")
        _ = try await sendMessageAsync("0100", withTimeoutSecs: 10)

        let obdProtocolNumber = try await sendMessageAsync("ATDPN")
        guard let obdProtocol = PROTOCOL(rawValue: String(obdProtocolNumber[0].dropFirst())) else {
            throw SetupError.invalidResponse(message: "Invalid protocol number: \(obdProtocolNumber)")
        }

        try await testProtocol(obdProtocol: obdProtocol)

        return obdProtocol
    }

    private func manualProtocolDetection(desiredProtocol: PROTOCOL?) async throws -> PROTOCOL? {
        if let desiredProtocol = desiredProtocol {
            try? await testProtocol(obdProtocol: desiredProtocol)
            return desiredProtocol
        }
        while obdProtocol != .NONE {
            do {
                try await testProtocol(obdProtocol: obdProtocol)
                return obdProtocol // Exit the loop if the protocol is found successfully
            } catch {
                // Other errors are propagated
                obdProtocol = obdProtocol.nextProtocol()
            }
        }
        // If we reach this point, no protocol was found
        logger.error("No protocol found")
        throw SetupError.noProtocolFound
    }

    // MARK: - Protocol Testing

    private func testProtocol(obdProtocol: PROTOCOL) async throws {
        // test protocol by sending 0100 and checking for 41 00 response
        _ = try await okResponse(message: obdProtocol.cmd)

        let r100 = try await sendMessageAsync("0100", withTimeoutSecs: 10)

        if r100.joined().contains("NO DATA") {
            throw SetupError.ignitionOff
        }

        guard r100.joined().contains("41 00") else {
            logger.error("Invalid response to 0100")
            throw SetupError.invalidProtocol
        }

        logger.info("Protocol \(obdProtocol.rawValue) found")

        let response = try await sendMessageAsync("0100", withTimeoutSecs: 10)
        let messages = try OBDParcer(response, idBits: obdProtocol.idBits).messages

        _ = populateECUMap(messages)
    }

    func adapterInitialization(setupOrder: [OBDCommand.General] = [.ATD, .ATZ, .ATL0, .ATE0, .ATH1, .ATAT1, .ATRV, .ATDPN]) async throws {
        for step in setupOrder {
            switch step {
            case .ATD, .ATL0, .ATE0, .ATH1, .ATAT1, .ATSTFF, .ATH0:
                _ = try await okResponse(message: step.properties.command)
            case .ATZ:
                _ = try await sendMessageAsync(step.properties.command)
            case .ATRV:
                // get the voltage
               _ = try await sendMessageAsync(step.properties.command)
            case .ATDPN:
                // Describe current protocol number
                let protocolNumber = try await sendMessageAsync(step.properties.command)
                self.obdProtocol = PROTOCOL(rawValue: protocolNumber[0]) ?? .protocol9
            }
        }
    }

    private func setHeader(header: String) async throws {
        _ = try await okResponse(message: "AT SH " + header)
    }

    func stopConnection() {
        bleManager.disconnectPeripheral()
    }

    // MARK: - Message Sending

    func sendMessageAsync(_ message: String, withTimeoutSecs: TimeInterval = 5) async throws -> [String] {
        return try await self.bleManager.sendMessageAsync(message)
    }

    private func okResponse(message: String) async throws -> [String] {
        let response = try await self.sendMessageAsync(message)
        if response.contains("OK") {
            return response
        } else {
            logger.error("Invalid response: \(response)")
            throw SetupError.invalidResponse(message: response[0])
        }
    }

    func getStatus() async throws -> Status? {
        let statusCommand = OBDCommand.Mode1.status
        let statusResponse = try await sendMessageAsync(statusCommand.properties.command)
        let statueMessages = try OBDParcer(statusResponse, idBits: obdProtocol.idBits).messages

        guard let statusData = statueMessages[0].data else {
            return nil
        }
        guard let decodedStatus = statusCommand.properties.decoder.decode(data: statusData) else {
            return nil
        }
        switch decodedStatus {
        case .statusResult(let value):
            return value
        default:
            return nil
        }
    }

    func scanForTroubleCodes() async throws -> [TroubleCode]? {
        let dtcCommand = OBDCommand.Mode3.GET_DTC
        let dtcResponse = try await sendMessageAsync(dtcCommand.properties.command)

        let dtcMessages = try OBDParcer(dtcResponse, idBits: obdProtocol.idBits).messages

        guard let dtcData = dtcMessages[0].data else {
            return nil
        }
        guard let decodedDtc = dtcCommand.properties.decoder.decode(data: dtcData) else {
            return nil
        }

        switch decodedDtc {
        case .troubleCode(let value):
            return value
        default:
            return nil
        }
    }

    func clearTroubleCodes() async throws {
        let command = OBDCommand.Mode4.CLEAR_DTC

        let response = try await sendMessageAsync(command.properties.command)
        print("Response: \(response)")
    }

    private func requestVin() async -> String? {
        let command = OBDCommand.Mode9.VIN
        guard let vinResponse = try? await sendMessageAsync(command.properties.command) else {
            return nil
        }

        let messages = try? OBDParcer(vinResponse, idBits: obdProtocol.idBits).messages
        guard let data = messages?[0].data,
                var vinString = String(bytes: data, encoding: .utf8) else {
            return nil
        }

        vinString = vinString
            .replacingOccurrences(of: "[^a-zA-Z0-9]",
                                  with: "",
                                  options: .regularExpression)

        return vinString
    }
}

extension ELM327 {
    func requestPIDs(_ pids: [OBDCommand]) async throws -> [Message] {
        let response = try await sendMessageAsync("01" + pids.compactMap { $0.properties.command.dropFirst(2) }.joined())
        return try OBDParcer(response, idBits: obdProtocol.idBits).messages
    }

    private func populateECUMap(_ messages: [Message]) -> [UInt8: ECUID]? {
        let engineTXID = 0
        let transmissionTXID = 1
        var ecuMap: [UInt8: ECUID] = [:]

        // If there are no messages, return an empty map
        guard !messages.isEmpty else {
            return nil
        }

        // If there is only one message, assume it's from the engine
        if messages.count == 1 {
            ecuMap[messages[0].ecu?.rawValue ?? 0] = .engine
            return ecuMap
        }

        // Find the engine and transmission ECU based on TXID
        var foundEngine = false

        for message in messages {
            guard let txID = message.ecu?.rawValue else {
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
                guard let bits = message.data?.bitCount() else {
                    logger.error("parse_frame failed to extract data")
                    continue
                }
                if bits > bestBits {
                    bestBits = bits
                    bestTXID = message.ecu?.rawValue
                }
            }

            if let bestTXID = bestTXID {
                ecuMap[bestTXID] = .engine
            }
        }

        // Assign transmission ECU to messages without an ECU assignment
        for message in messages where ecuMap[message.ecu?.rawValue ?? 0] == nil {
            ecuMap[message.ecu?.rawValue ?? 0] = .transmission
        }

        return ecuMap
    }
}

struct BatchedResponse {
    private var buffer: Data

    init(response: Data) {
        self.buffer = response
    }

    mutating func getValueForCommand(_ cmd: OBDCommand) -> OBDDecodeResult? {
        guard buffer.count >= cmd.properties.bytes else {
            return nil
        }
        let value = buffer.prefix(cmd.properties.bytes)
        //        print("value ",value.compactMap { String(format: "%02X ", $0) }.joined())
        
        buffer.removeFirst(cmd.properties.bytes)
        //        print("Buffer: \(buffer.compactMap { String(format: "%02X ", $0) }.joined())")

        return cmd.properties.decoder.decode(data: value.dropFirst())
    }
}
