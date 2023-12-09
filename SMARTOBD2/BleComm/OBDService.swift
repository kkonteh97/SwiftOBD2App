//
//  SettingsScreenViewModel.swift
//  SmartOBD2
//
//  Created by kemo konteh on 8/31/23.
//

import Foundation
import CoreBluetooth
import Combine

struct OBDInfo: Codable {
    var vin: String?
    var supportedPIDs: [OBDCommand]?
    var obdProtocol: PROTOCOL?
    var ecuMap: [UInt8: ECUID]?
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

struct DeviceInfo {
    let DeviceName: String
    let serviceUUID: String
    let peripheralUUID: String
}

enum OBDDevice: CaseIterable {
    case carlyOBD
    case mockOBD
    case other

    var properties: DeviceInfo {
        switch self {
        case .carlyOBD:
            return DeviceInfo(DeviceName: "Carly",
                              serviceUUID: "FFE0",
                              peripheralUUID: "5B6EE3F4-2FCA-CE45-6AE7-8D7390E64D6D"
            )
        case .mockOBD:
            return DeviceInfo(DeviceName: "MockOBD",
                              serviceUUID: "FFE0",
                              peripheralUUID: "Random"
            )
        case .other:
            return DeviceInfo(DeviceName: "Other",
                              serviceUUID: "Unknown",
                              peripheralUUID: "Mystery"
            )
        }
    }
}

class OBDService {
    @Published var elmAdapter: CBPeripheralProtocol?
    @Published var connectionState: ConnectionState = .notConnected
    @Published var userDevice: OBDDevice = .carlyOBD

    var elm327: ELM327

    private var cancellables = Set<AnyCancellable>()
    private let bleManager: BLEManager
    @Published var isDemoMode: Bool = false {
        didSet {
            switchToDemoMode(isDemoMode)
        }
    }

    @Published var previousDevice: OBDDevice? = nil


    init(bleManager: BLEManager = BLEManager()) {
        self.bleManager = bleManager
        self.elm327 = ELM327(bleManager: bleManager)
        bleManager.$connectionState
            .sink { [weak self] state in
                self?.connectionState = state
            }
            .store(in: &cancellables)
    }

    func switchToDemoMode(_ isDemoMode: Bool) {
        switch isDemoMode {
        case true:
            previousDevice = userDevice
            bleManager.isDemoMode = true
            userDevice = .mockOBD
        case false:
            if let previousDevice = previousDevice {
                userDevice = previousDevice
            }
            bleManager.isDemoMode = false
            previousDevice = nil
        }

    }

    func startConnection(setupOrder: [OBDCommand.General], obdinfo: OBDInfo) async throws -> OBDInfo {
        try await initAdapter(setupOrder: setupOrder, device: userDevice)
        var vehicleInfo = try await initVehicle(obdinfo: obdinfo)
        vehicleInfo.supportedPIDs = await elm327.getSupportedPIDs()
        vehicleInfo.vin = await requestVin()
        return vehicleInfo
    }

    func initAdapter(setupOrder: [OBDCommand.General], device: OBDDevice) async throws {
        if bleManager.connectionState != .connectedToAdapter {
            let foundPeripheral = try await scanForPeripheral(device: device.properties)
            print("\n")
            self.elmAdapter = try await connect(to: foundPeripheral)
        }
        try await elm327.adapterInitialization(setupOrder: setupOrder)
        DispatchQueue.main.async {
            self.connectionState = .connectedToAdapter
        }
    }

    func initVehicle(obdinfo: OBDInfo) async throws -> OBDInfo {
        let vehicleInfo =  try await elm327.setupVehicle(desiredProtocol: obdinfo.obdProtocol)
        DispatchQueue.main.async {
            self.connectionState = .connectedToVehicle
        }
        return vehicleInfo
    }

    func requestVin() async -> String? {
        return await elm327.requestVin()
    }

    func scanForPeripheral(device: DeviceInfo) async throws -> Peripheral {
        guard let peripheral = try await bleManager.scanForPeripheralAsync(device: device) else {
            throw OBDServiceError.noAdapterFound
        }
        return peripheral
    }

    func connect(to peripheral: Peripheral) async throws  -> CBPeripheralProtocol {
        let connectedPeripheral = try await bleManager.connectAsync(peripheral: peripheral)
        setEcuCharacteristic(peripheral: connectedPeripheral)
        return connectedPeripheral
    }

    func setEcuCharacteristic(peripheral: CBPeripheralProtocol) {
        for service in peripheral.services ?? [] {
            for characteristic in service.characteristics ?? [] {
                if characteristic.properties.contains(.notify) {
                    peripheral.setNotifyValue(true, for: characteristic)
                }
                if characteristic.properties.contains(.write) && characteristic.properties.contains(.read) {
                    elm327.ecuCharacteristic = characteristic
                }
            }
        }
    }

    func scanForTroubleCodes() async throws -> [TroubleCode]? {
        return try await elm327.scanForTroubleCodes()
    }
}

enum OBDServiceError: Error {
    case noAdapterFound
    case noVehicleSelected
}
