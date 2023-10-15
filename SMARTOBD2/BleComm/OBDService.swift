//
//  SettingsScreenViewModel.swift
//  SmartOBD2
//
//  Created by kemo konteh on 8/31/23.
//

import Foundation
import CoreBluetooth
import Combine

struct Vehicle: Codable {
    let make: String
    let model: String
    let year: Int
    let obdinfo: OBDInfo
}

struct OBDInfo: Codable {
    var vin: String?
    var supportedPIDs: [OBDCommand]?
    var obdProtocol: PROTOCOL = .NONE
    var ecuMap: [UInt8: ECUID]?
}

struct Manufacturer: Codable {
    let make: String
    let models: [Model]
}

struct Model: Codable {
    let name: String
    let years: [Int]
}

struct PIDData {
    let pid: OBDCommand
    var value: Double
    var unit: String
}

struct VINResults: Codable {
    let Results: [VINInfo]
}

struct VINInfo: Codable, Hashable {
    let Make: String
    let Model: String
    let ModelYear: String
    let EngineCylinders: String
}

class OBDService {
    let elm327: ELM327
    
    @Published var elmAdapter: CBPeripheral?
    private var cancellables = Set<AnyCancellable>()
    @Published var statusMessage: String?
    private var bleManager: BLEManager

    init(bleManager: BLEManager) {
        self.bleManager = bleManager
        self.elm327 = ELM327(bleManager: bleManager)
        subscribeToElmAdapterChanges()
    }

    private func subscribeToElmAdapterChanges() {
        elm327.bleManager.$connectedPeripheral
            .sink { [weak self] elmAdapter in
                self?.elmAdapter = elmAdapter
            }
            .store(in: &cancellables)

        elm327.$statusMessage
            .sink { [weak self] message in
                self?.statusMessage = message
            }
            .store(in: &cancellables)
    }

    func setupAdapter(setupOrder: [SetupStep]) async throws -> OBDInfo {
        return try await elm327.setupAdapter(setupOrder: setupOrder)
    }

    // connect to the adapter
    func connectToAdapter(peripheral: CBPeripheral) async throws {
        _ = try await self.bleManager.connectAsync(peripheral: peripheral)
    }


    func requestDTC() async {
        do {
            try await elm327.requestDTC()

        } catch {
            print(error.localizedDescription)
        }
    }
}
