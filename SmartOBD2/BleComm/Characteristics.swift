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
        if let characteristics = service.characteristics {
            // Create an empty array to store characteristics for this service
            var characteristicArray: [CBCharacteristic] = []
            for characteristic in characteristics {
                // if notifiable, turn on notifications
                if characteristic.properties.contains(.notify) {
                    peripheral.setNotifyValue(true, for: characteristic)
                }
                
                characteristicArray.append(characteristic)
                if characteristic.uuid.uuidString == "FFE1" {
                    ecuCharacteristic = characteristic
                    // Write initiatization commands
                    for command in initCommands {
                        let data = command.data(using: .utf8)
                        peripheral.writeValue(data!, for: characteristic, type: .withResponse)
                    }
                    print("initialized")
                    initialized = true
                }
            }
            // Add the service and its associated characteristics to the test dictionary
            test[service] = characteristicArray
        }
    }


}
