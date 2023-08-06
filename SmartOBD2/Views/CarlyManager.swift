//
//  File.swift
//  Obd2Scanner
//
//  Created by kemo konteh on 8/1/23.
//

import Foundation
import CoreBluetooth

class CarlyBleManager {
    let TAG: String
    let elmServiceUUID: UUID
    let elmServiceCharacteristicUUID: UUID
    let firmwareServiceUUID: UUID
    let firmwareServiceCharacteristicUUID: UUID
    
    @Published var BLE_CHARACTERISTIC_DESCRIPTOR_UUID = 10498;
    @Published var BLE_DEVICE_FIRMWARE_CHARACTERISTIC_UUID = 10790;
    @Published var BLE_DEVICE_FIRMWARE_UUID = 6154;
    @Published var BLE_ELM_SERVICE_CHARACTERISTIC_UUID = 65505;
    @Published var BLE_ELM_SERVICE_UUID = 65504;
    
    init(TAG: String, elmServiceUUID: UUID, elmServiceCharacteristicUUID: UUID, firmwareServiceUUID: UUID, firmwareServiceCharacteristicUUID: UUID, BLE_CHARACTERISTIC_DESCRIPTOR_UUID: Int = 10498, BLE_DEVICE_FIRMWARE_CHARACTERISTIC_UUID: Int = 10790, BLE_DEVICE_FIRMWARE_UUID: Int = 6154, BLE_ELM_SERVICE_CHARACTERISTIC_UUID: Int = 65505, BLE_ELM_SERVICE_UUID: Int = 65504) {
        self.TAG = TAG
        self.elmServiceUUID = elmServiceUUID
        self.elmServiceCharacteristicUUID = elmServiceCharacteristicUUID
        self.firmwareServiceUUID = firmwareServiceUUID
        self.firmwareServiceCharacteristicUUID = firmwareServiceCharacteristicUUID
        self.BLE_CHARACTERISTIC_DESCRIPTOR_UUID = BLE_CHARACTERISTIC_DESCRIPTOR_UUID
        self.BLE_DEVICE_FIRMWARE_CHARACTERISTIC_UUID = BLE_DEVICE_FIRMWARE_CHARACTERISTIC_UUID
        self.BLE_DEVICE_FIRMWARE_UUID = BLE_DEVICE_FIRMWARE_UUID
        self.BLE_ELM_SERVICE_CHARACTERISTIC_UUID = BLE_ELM_SERVICE_CHARACTERISTIC_UUID
        self.BLE_ELM_SERVICE_UUID = BLE_ELM_SERVICE_UUID
    }
    
    func uuidFromInteger(i: Int) -> UUID {
        let upperBits: UInt64 = UInt64(i & (-1)) << 32
        let lowerBits: UInt64 = 0x8000000000000000 // (-9223371485494954757L) in decimal
        let uuidBits = upperBits | lowerBits
        
        let msb: UInt64 = (uuidBits >> 32) & 0xFFFF_FFFF
        let lsb: UInt64 = uuidBits & 0xFFFF_FFFF
        
        var bytes: [UInt8] = []
        
        for i in 0..<8 {
            bytes.append(UInt8((msb >> (8 * (7 - i))) & 0xFF))
        }
        
        for i in 0..<8 {
            bytes.append(UInt8((lsb >> (8 * (7 - i))) & 0xFF))
        }
        
        return UUID(uuidString: String(bytes: bytes, encoding: .utf8)!)!
    }
}

