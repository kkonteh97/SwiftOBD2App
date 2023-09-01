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

extension BLEManager {
    
    func getECUs(response: String) -> [String]? {
        var ecu: [String] = []
        
        let ecuSegments = response.components(separatedBy: " ")
        var index = 0

        while index < ecuSegments.count {
            let hexString = ecuSegments[index]
            
            if hexString == "41" {
                let ecufound = ecuSegments[index - 2]
                ecu.append(ecufound)
                switch ecufound {
                case "10":
                    
                    print("AT CRA\((ecuSegments[0...(index - 2)]).joined())")
                    self.craFilter = "AT CRA\((ecuSegments[0...(index - 2)]).joined())"
                default:
                    break
                }
            }
            index += 1

        }
        
        return ecu
    }
    
    
    func getSupportedPIDs(response: String)  {
        let response = response.components(separatedBy: " ")
        print(response)
        
        let indexof41 = response.firstIndex(of: "41") ?? response.endIndex
        let startIndex = response.index(indexof41, offsetBy: 2, limitedBy: response.endIndex) ?? response.endIndex
        // filter 55 out
        
        let bytes = response[startIndex...]
            .filter { $0 != "55" }
            .compactMap { UInt8(String($0), radix: 16) }
        
        print(bytes)

        

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
    
        let supportedPIDsByECU = supportedPIDs.map { pid in
             PIDs(rawValue: pid)
        }
        
        
        // remove nils
        self.supportedPIDsByECU = supportedPIDsByECU
                                    .map { $0 }
                                    .compactMap { $0 }
        
        self.pidDescriptions = supportedPIDsByECU
                                    .map { $0?.description }
                                    .compactMap { $0 }


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
    
    //return all but last character
    return String(endStr.dropLast())
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
    
    func parse_0101(_ linesToParse: [String], obdProtocol: PROTOCOL) -> Int{
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
    
    func parseDTCs(_ howMany: Int, linesToParse: [String], obdProtocol: PROTOCOL) -> (Bool, [String]){
        
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
