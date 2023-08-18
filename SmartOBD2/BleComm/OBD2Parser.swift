//
//  Obd2Parser.swift
//  SmartOBD2
//
//  Created by kemo konteh on 8/7/23.
//

import Foundation

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

extension BluetoothViewModel {
    
    func getSupportedPIDs(response: [String])  -> (pidDescriptions: [String], supportedPIDsByECU: [String]) {
        var supportedPIDsByECU: [String] = []
        
        let linesAsStr = linesToStr(response.dropLast())
        
        let ecuSegments = linesAsStr.components(separatedBy: "18 DA F1 ")
        
        for ecuSegment in ecuSegments.dropFirst() {
            let ecuData = String(ecuSegment).dropFirst(12).dropLast(4)
            
            let Bytes = ecuData.split(separator: " ").compactMap { String($0) }
            // Convert each byte to binary and join them together
            let binaryData = Bytes
                .compactMap { Int($0, radix: 16) }
                .map { String($0, radix: 2).leftPadding(toLength: 8, withPad: "0") }
                .joined()
            
            // Define the PID numbers based on the binary data
            let supportedPIDs = binaryData.enumerated()
                .compactMap { index, bit -> String? in
                    if bit == "1" {
                        let pidNumber = String(format: "%02X", index + 1)
                        return pidNumber
                    }
                    return nil
                    
                }
            
            // append unique pids to supportedPIDsByECU
            for pid in supportedPIDs {
                if !supportedPIDsByECU.contains(pid) {
                    supportedPIDsByECU.append(pid)
                }
            }
        }
        let supportedPIDsEnum: [ELM327.PIDs] = supportedPIDsByECU.compactMap { ELM327.PIDs(rawValue: $0) }
        print(supportedPIDsEnum)
        // pidDescriptions
        let pidDescriptions = supportedPIDsEnum.map { $0.description }
        let _ = supportedPIDsEnum.map { $0.rawValue }
        self.PIDsReady = true        
        return (pidDescriptions, supportedPIDsByECU)
    }
    
    func requestPids1(pids: [String]) {
        // slice pids into groups of 6
        let pidsGroups = pids.chunked(into: 6)
        for group in pidsGroups {
            let pidsStr = group.joined(separator: " ")
            let cmd = "01 \(pidsStr)"
            print(cmd)
            let cmdBytes = cmd.data(using: .utf8)!
            print(cmdBytes)
        }
        
    }
}


public func linesToStrArray(_ linesToParse: [String]) -> [String]{
    var allBytesTogether: [String] = []
    
    for line in linesToParse {
        let bytesArr = line.split{$0 == " "}.map(String.init)
        for bytes in bytesArr {
            allBytesTogether.append(bytes)
        }
    }
    return allBytesTogether
}

public func linesToStr(_ linesToParse: [String]) -> String{
    var endStr = ""
        
    for str in linesToParse {
        endStr.append(str)
    }
    
    return endStr
}


class OBDParser: NSObject {
    
    //SINGLETON INSTANCE
    static let sharedInstance = OBDParser()
    
    override fileprivate init(){
        super.init()
    }
    
    ////////////////////////////////////////////////////////
    // MARK: PARSING
    ////////////////////////////////////////////////////////
    
    func parse_0101(_ linesToParse: [String], obdProtocol: ELM327.PROTOCOL) -> Int{
        print("Parsing 0101")
        
        let linesAsStrArr = linesToStrArray(linesToParse)
        
        if linesAsStrArr.count > 1 {
            if let numberOfDtcs = Int(linesAsStrArr[2]) {
                return numberOfDtcs - 80
            }else {
//                log.error("Number of DTCs could not be parsed from \(linesAsStrArr)")
                return 0
            }
        }else {return 0}
    }
    
    func parseDTCs(_ howMany: Int, linesToParse: [String], obdProtocol: ELM327.PROTOCOL) -> (Bool, [String]){
        
        if(howMany <= 0){
            return (false, [])
        }
        
        _ = linesToStr(linesToParse)
        
        var dtcsArray: [String] = []
        var parsingDTCs: Bool = false
        var dtcsToParse: Int = 0
        var parsedDTCs: Int = 0
        
        for line in linesToParse {
            
            let bytesArr = line.split{$0 == " "}.map(String.init)
            let count = bytesArr.count
            
            let bytePair1: String = count > 0 ? bytesArr[0] : ""
            let bytePair2: String = count > 1 ? bytesArr[1] : ""
            let bytePair3: String = count > 2 ? bytesArr[2] : ""
            let bytePair4: String = count > 3 ? bytesArr[3] : ""
            let bytePair5: String = count > 4 ? bytesArr[4] : ""
            let bytePair6: String = count > 5 ? bytesArr[5] : ""
            let bytePair7: String = count > 6 ? bytesArr[6] : ""
//            let bytePair8: String = count > 6 ? bytesArr[6] : ""
            
            
            // TODO
            
            if (bytePair1 == "43" && !parsingDTCs){ // Single line
                parsingDTCs = true
                
                //Get number of DTCs that need to be parsed
                if let dtcs = Int(bytePair2) {
                    dtcsToParse = dtcs
                }else {
                    print("Problem parsing number of DTCs")
                
                }
                
                //Parse the first line
                let dtc1 = OBDDTC.parseRawOBDErrorCode("\(bytePair3)\(bytePair4)")
                dtcsArray.append(dtc1!)
                parsedDTCs += 1
                
                if parsedDTCs == dtcsToParse { break }
                
                let dtc2 = OBDDTC.parseRawOBDErrorCode("\(bytePair5)\(bytePair6)")
                dtcsArray.append(dtc2!)
                parsedDTCs += 1
                
            }else if (bytePair1 == "0:" && bytePair2 == "43" && !parsingDTCs){ // Multiple lines
                parsingDTCs = true
                
                //Get number of DTCs that need to be parsed
                if let dtcs = Int(bytePair3) {
                    dtcsToParse = dtcs
                }else {
                    print("Problem parsing number of DTCs")
                    
                
                }
                
                let dtc1 = OBDDTC.parseRawOBDErrorCode("\(bytePair4)\(bytePair5)")
                dtcsArray.append(dtc1!)
                parsedDTCs += 1
                
                if parsedDTCs == dtcsToParse { break }
                
                let dtc2 = OBDDTC.parseRawOBDErrorCode("\(bytePair6)\(bytePair7)")
                dtcsArray.append(dtc2!)
                parsedDTCs += 1
                
            }else if parsingDTCs {
                
                if parsedDTCs == dtcsToParse { break }
                
                let dtc1 = OBDDTC.parseRawOBDErrorCode("\(bytePair2)\(bytePair3)")
                dtcsArray.append(dtc1!)
                parsedDTCs += 1
                
                if parsedDTCs == dtcsToParse { break }
                
                let dtc2 = OBDDTC.parseRawOBDErrorCode("\(bytePair4)\(bytePair5)")
                dtcsArray.append(dtc2!)
                parsedDTCs += 1
                
                if parsedDTCs == dtcsToParse { break }
                
                let dtc3 = OBDDTC.parseRawOBDErrorCode("\(bytePair6)\(bytePair7)")
                dtcsArray.append(dtc3!)
                parsedDTCs += 1
                
            }else {
                print("Problem parsing DTCs")
                
            }
            
        }
        
        return (true, dtcsArray)
    }// END of PARSE DTCs
    
}
