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
    private var getRPMCommand = "0100\r"
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
    
    func processBuffer(response: String) -> Int {
        let pattern = "([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})555555"
        let range = response.range(of: pattern, options: .regularExpression)

        // Process the pattern occurrence in the buffer
        guard let matchedRange = range else {
            return currentRPM
        
        }
        let rpmData = response[matchedRange]

        guard let rpmValue = UInt(rpmData.prefix(4), radix: 16) else {
            print("Invalid RPM value")
            return currentRPM
        
        }
        self.currentRPM = Int(rpmValue) / 4
        return Int(rpmValue) / 4
        }
    
    func decodeSupportedPIDs(hexResponse: String, totalPIDs: Int) -> [Int] {
        // Convert the hexadecimal response to binary
        let binaryResponse = hexResponse
            .compactMap { Int(String($0), radix: 16) }
            .map { String($0, radix: 2, uppercase: false) }
            .map { String(repeating: "0", count: 4 - $0.count) + $0 }
            .joined()
        
        // Pad the binary response to the total number of PIDs
        let paddedBinaryResponse = binaryResponse.padding(toLength: totalPIDs, withPad: "0", startingAt: 0)
        
        // Extract the supported PIDs
        var supportedPIDs: [Int] = []
        for (index, char) in paddedBinaryResponse.enumerated() {
            if char == "1" {
                supportedPIDs.append(index + 1) // PIDs start from 1
            }
        }
        
        return supportedPIDs
    }
    
    func startRPMRequest(characteristic: CBCharacteristic, peripheral: CBPeripheral) {
        // Make sure the RPM timer is stopped before starting a new one
//        stopRPMRequest()
        let data = self.getRPMCommand.data(using: .utf8)
        peripheral.writeValue(data!, for: characteristic, type: .withResponse)
        
        // Start a new timer to send RPM requests every X seconds
//        rpmTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
//            guard let self = self else { return }
//            let data = self.getRPMCommand.data(using: .utf8)
//            peripheral.writeValue(data!, for: characteristic, type: .withResponse)
//        }
    }
    
    func stopRPMRequest() {
        rpmTimer?.invalidate()
        rpmTimer = nil
    }

}
