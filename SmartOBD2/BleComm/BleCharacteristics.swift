//
//  DiscoverCharacteristics.swift
//  Obd2Scanner
//
//  Created by kemo konteh on 8/3/23.
//

import Foundation
import CoreBluetooth


extension BluetoothViewModel {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else {
            print("No characteristics found")
            return
        }
        // Create an empty array to store characteristics for this service
        var characteristicArray: [CBCharacteristic] = []
        for characteristic in characteristics {
            // if notifiable, turn on notifications
            if characteristic.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: characteristic)
            }
            
            characteristicArray.append(characteristic)
            switch characteristic.uuid.uuidString {
            case "FFE1":
                ecuCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
                // Write initiatization commands
                elm?.setupAdapter()
                elm?.initializeELM(peripheral: connectedPeripheral!, characteristic: characteristic)
            default:
                if characteristic.properties.contains(.notify) {
                    peripheral.setNotifyValue(true, for: characteristic)
                    
                }
            }
            // Add the service and its associated characteristics to the test dictionary
            test[service] = characteristicArray
        }
    }


}
