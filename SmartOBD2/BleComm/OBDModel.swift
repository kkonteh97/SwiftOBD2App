//
//  OBDModel.swift
//  SmartOBD2
//
//  Created by kemo konteh on 8/7/23.
//

import Foundation
import SwiftyJSON

/**
 
 Class for DTC (Dynamic Trouble Code)
 
 */
class OBDDTC: NSObject {
    //CLASS PROPERTIES
    fileprivate static let PREFIXES: [String: String] = ["0":"P0","1":"P1","2":"P2","3":"P3",
                                                     "4":"C0","5":"C1","6":"C2","7":"C3",
                                                     "8":"B0","9":"B1","A":"B2","B":"B3",
                                                     "C":"U0","D":"U1","E":"U2","F":"U3"]
    
    let DTC: String
    let system: String
    let fault: String
    
    init(DTC: String, system: String, fault: String) {
        self.DTC = DTC
        self.system = system
        self.fault = fault
    }
    
    /**
     Use this method for example to convert from 0001 to P0001
     */
    class func parseRawOBDErrorCode(_ rawCode: String) -> String? {
        if(rawCode.count == 4){
            
            let rawCodeStrArray = [Character](rawCode)
            
            return "\(PREFIXES["\(rawCodeStrArray[0])"]!)\(rawCodeStrArray[1])\(rawCodeStrArray[2])\(rawCodeStrArray[3])"
            
        }else{
            return nil
        }
    }
}

