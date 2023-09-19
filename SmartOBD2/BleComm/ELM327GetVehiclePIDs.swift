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
                let response = try await sendMessageAsync(pid.cmd)[0].components(separatedBy: " ")
                // find first instance of 41 plus command sent, from there we determine the position of everything else
                // Ex.
                //        || ||
                // 7E8 06 41 00 BE 7F B8 13

                guard let startIndex = response.firstIndex(of: "41"),
                        startIndex + 1 < response.count && response[startIndex + 1] == pid.cmd.dropFirst(2) else {
                    return []
                }

                do {
                    guard let dataLen = try extractDataLength(startIndex, response),
                          let endIndex = response.index(
                            startIndex, offsetBy: dataLen, limitedBy: response.endIndex
                          ) else {
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

                    if obdProtocol.idBits == 11 {
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
                    for modeCommand in modeCommands
                    where supportedPIDsByECU.contains(String(modeCommand.cmd.dropFirst(2))) {
                               supportedPIDsSet.insert(modeCommand) // Add to supported PIDs set
                       }
                } catch {
                    logger.error("\(error.localizedDescription)")
                }
            } catch {
                logger.error("\(error.localizedDescription)")
            }
        }
        // Convert the set back to an array before returning it
        let supportedPIDsArray = Array(supportedPIDsSet)

        return supportedPIDsArray
    }

    func extractSupportedPIDs(_ binaryData: String) -> [String] {
        return binaryData.enumerated()
            .compactMap { index, bit -> String? in
                if bit == "1" {
                    let pidNumber = String(format: "%02X", index + 1)
                    return pidNumber
                }
                return nil
            }
    }

    public func extractDataLength(_ startIndex: Int, _ response: [String]) throws -> Int? {
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
}
