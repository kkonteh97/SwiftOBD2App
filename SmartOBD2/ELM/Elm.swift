//
//  Elm.swift
//  SmartOBD2
//
//  Created by kemo konteh on 8/5/23.
//

import Foundation
import CoreBluetooth



class ELMComm: ObservableObject {
    


    

    
    
    
    func decodeRPM(response: String) {
        let pattern = "([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})555555"
        let range = response.range(of: pattern, options: .regularExpression)
        
        //         Process the pattern occurrence in the buffer
        guard let matchedRange = range else {
            return
            
        }
        let rpmData = response[matchedRange]
        
        guard let rpmValue = UInt(rpmData.prefix(4), radix: 16) else {
            print("Invalid RPM value")
            return
            
        }
        print("RPM: \(rpmValue)")
        return
    }
    
    func startRequest(characteristic: CBCharacteristic, peripheral: CBPeripheral) {
        //            Make sure the RPM timer is stopped before starting a new one
        stopRequest()
        
        //            Start a new timer to send RPM requests every X seconds
//        rpmTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
//            guard let self = self else { return }
        }
    }
    
    func stopRequest() {
//        rpmTimer?.invalidate()
//        rpmTimer = nil
    }
    

    

    
    
