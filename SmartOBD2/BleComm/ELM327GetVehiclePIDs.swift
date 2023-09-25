//
//  ELM327GetVehiclePIDs.swift
//  SmartOBD2
//
//  Created by kemo konteh on 9/19/23.
//

import Foundation

extension ELM327 {
    func getSupportedPIDs(_ obdProtocol: PROTOCOL) async -> [OBDCommand] {
        let pidGetters = Modes.pidGetters
        var supportedPIDsSet: Set<OBDCommand> = Set()

        for pid in pidGetters {
            do {
                let response = try await sendMessageAsync(pid.cmd)
                // find first instance of 41 plus command sent, from there we determine the position of everything else
                // Ex.
                //        || ||
                // 7E8 06 41 00 BE 7F B8 13
                let messages = call(response, idBits: obdProtocol.idBits)


                // Convert ecuData to binary and extract supported PIDs
                let binaryData = BitArray(data: messages[0].data)

                let supportedPIDsByECU = extractSupportedPIDs(binaryData.binaryArray)
                // Check if the supported PIDs are present in the predefined OBD commands
                let modeCommands = Modes.mode1
                // map supportedPIDsByECU to the modeCommands
                for modeCommand in modeCommands
                                where supportedPIDsByECU.contains(String(modeCommand.cmd.dropFirst(2))) {
                           supportedPIDsSet.insert(modeCommand) // Add to supported PIDs set
                   }
            } catch {
                logger.error("\(error.localizedDescription)")
            }
        }
        // Convert the set back to an array before returning it
        let supportedPIDsArray = Array(supportedPIDsSet)

        return supportedPIDsArray
    }

    func extractSupportedPIDs(_ binaryData: [Int]) -> [String] {
        return binaryData.enumerated()
            .compactMap { index, bit -> String? in
                if bit == 1 {
                    let pidNumber = String(format: "%02X", index + 1)
                    return pidNumber
                }
                return nil
            }
    }

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
        case .singleFrame:
            return Int(lengthHex) & 0x0F
        case .firstFrame:
            guard let secondLengthHex = UInt8(response[startIndex - 2], radix: 16) else {
                throw NSError(domain: "Invalid data format", code: 0, userInfo: nil)
            }
            return Int(lengthHex) + Int(secondLengthHex)
        case .consecutiveFrame:
            return Int(lengthHex)
        default:
            return nil
        }
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
}
