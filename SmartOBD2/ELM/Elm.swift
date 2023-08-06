//
//  Elm.swift
//  SmartOBD2
//
//  Created by kemo konteh on 8/5/23.
//

import Foundation
import CoreBluetooth

class ELMComm: ObservableObject {
    private var rpmTimer: Timer?
    private var getRPMCommand = "010C\r"
    @Published var currentRPM: Int = 0
    
//    func processBuffer() {
//        // return ranndom num between 700 and 8000 every 2 seconds
//
//        rpmTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
//            guard let self = self else { return }
//            self.currentRPM = Int.random(in: 700...8000)
//            print("Updated RPM: \(self.currentRPM)")
//        }
//
//
//
//    }
    
    func processBuffer(rpmData: Substring) -> Int {
        let rpmString = String(rpmData.filter { !$0.isWhitespace })

        guard let rpmValue = UInt(rpmString.prefix(4), radix: 16) else {
            print("Invalid RPM value")
            return currentRPM
        
        }
        print(Int(rpmValue) / 4)
        self.currentRPM = Int(rpmValue) / 4
        
        return Int(rpmValue) / 4
        }
    
    func startRPMRequest(characteristic: CBCharacteristic, peripheral: CBPeripheral) {
        // Make sure the RPM timer is stopped before starting a new one
        stopRPMRequest()
        
        // Start a new timer to send RPM requests every X seconds
        rpmTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let data = self.getRPMCommand.data(using: .utf8)
            peripheral.writeValue(data!, for: characteristic, type: .withResponse)
        }
    }
    
    func stopRPMRequest() {
        rpmTimer?.invalidate()
        rpmTimer = nil
    }

}
