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
    func sendMessageAsync(_ message: String,  withTimeoutSecs: TimeInterval) async throws -> [String]
    func setupAdapter(setupOrder: [SetupStep]) async throws -> OBDInfo
}

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
}

enum DataValidationError: Error {
    case oddDataLength
    case invalidDataFormat
    case insufficientDataLength
}

// MARK: - ELM327 Class

class ELM327: ObservableObject {

    // MARK: - Properties

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

    func setupAdapter(setupOrder: [SetupStep], autoProtocol: Bool = false) async throws -> OBDInfo {
        var obdInfo = OBDInfo()

        if bleManager.connectionState != .connectedToAdapter {
            try await connectToAdapter()
        }

        try await adapterInitialization(setupOrder: setupOrder)

        let obdProtocol = try await connectToVehicle(autoProtocol: autoProtocol)
        bleManager.connectionState = .connectedToVehicle

        obdInfo.obdProtocol = obdProtocol
        obdInfo.supportedPIDs = await getSupportedPIDs(obdProtocol)

        // Setup Complete will attempt to get the VIN Number
        if let vin = await requestVin() {
            obdInfo.vin = vin
        }

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
                case .ATD, .ATL0, .ATE0, .ATH1, .ATAT1, .ATSTFF:
                    _ = try await okResponse(message: step.rawValue)
                case .ATZ:
                    _ = try await sendMessageAsync("ATZ")
                case .ATRV:
                    // get the voltage
                    let voltage = try await sendMessageAsync("ATRV")
                    logger.info("Voltage: \(voltage)")
                case .ATDPN:
                    // Describe current protocol number
                    _ = try await sendMessageAsync("ATDPN")
                default:
                    logger.error("Invalid Setup Step")
                }
            }
        } catch {
            logger.error("\(error.localizedDescription)")
            throw SetupError.adapterInitFailed
        }
    }

    func connectToVehicle(autoProtocol: Bool) async throws -> PROTOCOL {
        if autoProtocol {
            guard let obdProtocol = try await autoProtocolDetection() else {
                logger.error("No protocol found")
                throw SetupError.noProtocolFound
            }
            return obdProtocol
        } else {
            guard let obdProtocol = try await manualProtocolDetection() else {
                logger.error("No protocol found")
                throw SetupError.noProtocolFound
            }
            return obdProtocol
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

            let obdProtocolNumber = try await sendMessageAsync("ATDPN")
            guard let obdProtocol = PROTOCOL(rawValue: obdProtocolNumber[0]) else {
                throw SetupError.invalidResponse
            }
            try await testProtocol(obdProtocol: obdProtocol)
            return obdProtocol
        } catch {
            logger.error("\(error.localizedDescription)")
            throw error
        }
    }

    func manualProtocolDetection() async throws -> PROTOCOL? {
        var obdProtocol: PROTOCOL = .protocol9
        while obdProtocol != .NONE {
            switch obdProtocol {
            case .protocol1, .protocol2, .protocol3, .protocol4, .protocol5, .protocol6,
                 .protocol7, .protocol8, .protocol9, .protocolA, .protocolB, .protocolC:
                do {
                    _ = try await okResponse(message: obdProtocol.cmd)
                    // test the protocol
                    _ = try await testProtocol(obdProtocol: obdProtocol)
                    return obdProtocol
                } catch {
                    obdProtocol = obdProtocol.nextProtocol()
                    if obdProtocol == .NONE {
                        logger.error("No protocol found")
                        throw SetupError.noProtocolFound
                    }
                }
            default:
                logger.error("Invalid Setup Step")
                throw SetupError.invalidResponse
            }
        }
        return nil
    }

    // MARK: - Protocol Testing

    func testProtocol(obdProtocol: PROTOCOL) async throws {
        do {
            // test protocol by sending 0100 and checking for 41 00 response
            _ = try await okResponse(message: obdProtocol.cmd)

            let r100 = try await sendMessageAsync("0100", withTimeoutSecs: 10)
            print(r100.joined())
            guard r100.joined().contains("41 00") else {
                logger.error("Invalid response to 0100")
                throw SetupError.invalidResponse
            }
        } catch {
            logger.error("\(error.localizedDescription)")
            throw error
        }
    }

    // connect to the adapter
    func connectToAdapter() async throws {
        bleManager.connectionState = .connecting
        _ = try await self.bleManager.scanAndConnectAsync(services: [self.elmServiceUUID])
        bleManager.connectionState = .connectedToAdapter
    }

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
}

// MARK: - Extension for Additional Functions

extension ELM327 {
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
}

