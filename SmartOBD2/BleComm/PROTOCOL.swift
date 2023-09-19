//
//  PROTOCOL.swift
//  SmartOBD2
//
//  Created by kemo konteh on 9/16/23.
//

import Foundation

extension String {
    var hexBytes: [UInt8] {
        var position = startIndex
        return (0..<count/2).compactMap { _ in
            defer { position = index(position, offsetBy: 2) }
            return UInt8(self[position...index(after: position)], radix: 16)
        }
    }
}

<<<<<<< HEAD
class Message {
    var frames: [Frame]
    var ecu: ECUID?
    var data = Data()
    var txID: UInt8? {
        return frames.first?.txID?.rawValue
    }
    init(frames: [Frame], ecu: ECUID = ECUID.unknown, data: Data = Data()) {
=======

public class Frame: Equatable {
    var raw: String
    var data = Data()
    var priority: UInt8?
    var addrMode: UInt8?
    var rxID: UInt8?
    var txID: UInt8?
    var type: UInt8?
    var seqIndex: UInt8 = 0 // Only used when type = CF
    var dataLen: UInt8?
    
    init(raw: String) {
        self.raw = raw
    }
    
    public static func == (lhs: Frame, rhs: Frame) -> Bool {
        if lhs.raw != rhs.raw || lhs.data != rhs.data || lhs.priority != rhs.priority || lhs.addrMode != rhs.addrMode || lhs.rxID != rhs.rxID || lhs.txID != rhs.txID || lhs.type != rhs.type || lhs.seqIndex != rhs.seqIndex || lhs.dataLen != rhs.dataLen {
            return false
        }
        return true
    }
}

extension Data {
    func hexEncodedString() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }

    func bitCount() -> Int {
        return self.count * 8
    }
}

extension Data {
    func hexString() -> String {
        return map { String(format: "%02hhx", $0) }.joined(separator: " ")
    }
}

class Message {
    var frames: [Frame]
    var ecu = ECU.UNKNOWN
    var data = Data()
    
    var txID: UInt8? {
        return frames.first?.txID
    }
    
    init(frames: [Frame], ecu: ECU = ECU.UNKNOWN, data: Data = Data()) {
>>>>>>> parent of 576eaca (Revert "dropped version down to ios 15")
        self.frames = frames
        self.ecu = ecu
        self.data = data
    }
}

<<<<<<< HEAD
class Frame {
    var raw: String
    var data = Data()
    var priority: UInt8?
    var addrMode: UInt8?
    var rxID: UInt8?
    var txID: ECUID?
    var type: FrameType?
    var seqIndex: UInt8 = 0 // Only used when type = CF
    var dataLen: UInt8?

    init(raw: String) {
        self.raw = raw
    }
}

enum FrameType: UInt8, Codable {
    case singleFrame = 0x00
    case firstFrame = 0x10
    case consecutiveFrame = 0x20
}

enum ECUID: UInt8, Codable {
    case engine = 0x00
    case transmission = 0x01
    case unknown = 0x02
}

enum TxId: UInt8, Codable {
    case engine = 0x00
    case transmission = 0x01
}

extension Data {
    func bitCount() -> Int {
        return self.count * 8
    }

    func hexString() -> String {
        return map { String(format: "%02hhx", $0) }.joined(separator: " ")
    }
}
=======
class OBDPROTOCOL {
    static var ELM_NAME = ""  // the ELM's name for this protocol (ie, "SAE J1939 (CAN 29/250)")
    static var ELM_ID = ""  // the ELM's ID for this protocol (ie, "A")

    static var TX_ID_ENGINE: UInt8? = nil
    static var TX_ID_TRANSMISSION: UInt8? = nil

    var ecuMap: [UInt8: ECU] = [:]

    init(lines0100: [String], idBits: Int) {

        if let txIDEngine = Self.TX_ID_ENGINE {
            ecuMap[txIDEngine] = .ENGINE
        }

        if let txIDTransmission = Self.TX_ID_TRANSMISSION {
            ecuMap[txIDTransmission] = .TRANSMISSION
        }
        let messages = call(lines0100)
        
        populateECUMap(messages)

        for (txID, ecu) in ecuMap {
            let ecuName = ecuNameForID(ecu)
            print("map ECU \(txID) --> \(ecuName)")
        }
    }

    func ecuNameForID(_ ecu: ECU) -> String {
        switch ecu {
        case .ALL:
            return "ALL"
        case .ALL_KNOWN:
            return "ALL_KNOWN"
        case .UNKNOWN:
            return "UNKNOWN"
        case .ENGINE:
            return "ENGINE"
        case .TRANSMISSION:
            return "TRANSMISSION"
        }
    }
         

    func populateECUMap(_ messages: [Message]) {

        let parsedMessages = messages

        if messages.isEmpty {
            return
        } else if messages.count == 1 {
            ecuMap[parsedMessages[0].txID ?? 0] = .ENGINE
        } else {
            var foundEngine = false

            for message in messages {
                guard let txID = message.txID else {
                    print("parse_frame failed to extract TX_ID")
                    continue
                }

                if txID == Self.TX_ID_ENGINE {
                    ecuMap[txID] = .ENGINE
                    foundEngine = true
                } else if txID == Self.TX_ID_TRANSMISSION {
                    ecuMap[txID] = .TRANSMISSION
                }

                // TODO: Add more cases for other ECUs

            }

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
                    ecuMap[bestTXID] = .ENGINE
                }
            }

            for message in messages where ecuMap[message.txID ?? 0] == nil {
                ecuMap[message.txID ?? 0] = .UNKNOWN
            }
        }
    }

    subscript(txID: UInt8) -> ECU {
        return ecuMap[txID] ?? .UNKNOWN
    }

    func parseFrame(_ frame: Frame) -> Bool {
            fatalError("Subclasses must implement this method")
        }

    func parseMessage(_ message: Message) -> Bool {
            fatalError("Subclasses must implement this method")
    }
    
    func isHex(_ str: String) -> Bool {
        let hexChars = CharacterSet(charactersIn: "0123456789ABCDEF")
        return str.uppercased().rangeOfCharacter(from: hexChars.inverted) == nil
    }
    
    

    func call(_ lines: [String]) -> [Message] {
            var obdLines = [String]()
            var nonOBDLines = [String]()

            for line in lines {
                let lineNoSpaces = line.replacingOccurrences(of: " ", with: "")

                if isHex(lineNoSpaces) {
                    obdLines.append(lineNoSpaces)
                } else {
                    nonOBDLines.append(line)
                }
            }

            var frames = [Frame]()
            for line in obdLines {
                let frame = Frame(raw: line)

                if parseFrame(frame) {
                    frames.append(frame)
                }
            }

            var framesByECU = [UInt8: [Frame]]()
            for frame in frames {
                if let txID = frame.txID {
                    if var frameArray = framesByECU[txID] {
                        frameArray.append(frame)
                        framesByECU[txID] = frameArray
                    } else {
                        framesByECU[txID] = [frame]
                    }
                }
            }

            var messages = [Message]()
            for ecu in framesByECU.keys.sorted() {
                let message = Message(frames: framesByECU[ecu] ?? [])
                
                
                if parseMessage(message) {
                    message.ecu = self[ecu]
                    messages.append(message)
                }
            }

            for line in nonOBDLines {
                messages.append(Message(frames: [Frame(raw: line)]))
            }

            return messages
        }
        
}

>>>>>>> parent of 576eaca (Revert "dropped version down to ios 15")
