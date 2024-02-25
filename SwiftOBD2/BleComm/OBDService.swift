//
//  SettingsScreenViewModel.swift
//  SmartOBD2
//
//  Created by kemo konteh on 8/31/23.
//

import Foundation
import CoreBluetooth
import Combine

struct OBDInfo: Codable, Hashable {
    var vin: String?
    var supportedPIDs: [OBDCommand]?
    var troubleCodes: [TroubleCode]?
    var obdProtocol: PROTOCOL?
    var ecuMap: [UInt8: ECUID]?
    var status: Status?
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

class OBDService: ObservableObject {
    @Published var connectedPeripheral: CBPeripheralProtocol? = nil
    @Published var connectionState: ConnectionState = .disconnected
    @Published var foundPeripherals: [Peripheral]?

    let setupOrder: [OBDCommand.General] = [.ATD, .ATZ, .ATL0, .ATE0, .ATH1, .ATAT1, .ATRV, .ATDPN]
    var elm327: ELM327
    let bleManager: BLEManager

    var cancellables = Set<AnyCancellable>()

    init() {
        self.bleManager = BLEManager()
        self.elm327 = ELM327(bleManager: bleManager)

        bleManager.$connectionState
            .sink { [weak self] state in
                self?.connectionState = state
            }
            .store(in: &cancellables)

        bleManager.$foundPeripherals
            .sink { [weak self] peripherals in
                self?.foundPeripherals = peripherals
            }
            .store(in: &cancellables)
    }

    func startConnection(_ obdinfo: inout OBDInfo) async throws {
        try await initAdapter()
        try await initVehicle(obdinfo: &obdinfo)
        obdinfo.supportedPIDs = await getSupportedPIDs()
    }

    func stopConnection() {
        self.connectionState = .disconnected
        self.elm327.stopConnection()
    }

    func initAdapter(timeout: TimeInterval = 7) async throws {
        if connectionState != .connectedToAdapter {
            let foundPeripheral = try await scanForPeripheral(timeout: timeout)
            _ = try await connect(to: foundPeripheral)
        }
        if bleManager.ecuWriteCharacteristic == nil || bleManager.ecuReadCharacteristic == nil {
            await bleManager.processCharacteristics()
        }
        try await elm327.adapterInitialization(setupOrder: setupOrder)
    }

    func scanForPeripheral(timeout: TimeInterval) async throws -> CBPeripheralProtocol {
        guard let peripheral = try await self.bleManager.scanForPeripheralAsync(timeout: timeout) else { throw OBDServiceError.noAdapterFound }
        return peripheral
    }

    func connect(to peripheral: CBPeripheralProtocol) async throws  -> CBPeripheralProtocol {
        let connectedPeripheral = try await self.bleManager.connectAsync(peripheral: peripheral)
        return connectedPeripheral
    }

    func initVehicle(obdinfo: inout OBDInfo) async throws {
        try await elm327.setupVehicle(obdInfo: &obdinfo)
        DispatchQueue.main.async {
            self.connectionState = .connectedToVehicle
        }
    }

    func getSupportedPIDs() async -> [OBDCommand] {
        return await elm327.getSupportedPIDs()
    }

    func scanForTroubleCodes() async throws -> [TroubleCode]? {
        guard self.connectionState == .connectedToVehicle else {
            throw OBDServiceError.notConnectedToVehicle
        }
        return try await elm327.scanForTroubleCodes()
    }

    func requestPIDs(_ commands: [OBDCommand]) async throws -> [Message] {
        return try await elm327.requestPIDs(commands)
    }

    func clearTroubleCodes() async throws {
        guard self.connectionState == .connectedToVehicle else {
            throw OBDServiceError.notConnectedToVehicle
        }
        try await elm327.clearTroubleCodes()
    }

    func getStatus() async throws -> Status? {
        return try await elm327.getStatus()
    }

//    func scanForPeripherals() {
//        bleManager.scanForPeripherals()
//    }

    func disconnectPeripheral(peripheral: Peripheral) {
        bleManager.disconnectPeripheral()
    }

    func switchToDemoMode(_ isDemoMode: Bool) {
        stopConnection()
        bleManager.demoModeSwitch(isDemoMode)
    }
}

enum OBDServiceError: Error, CustomStringConvertible {
    case noAdapterFound
    case notConnectedToVehicle
    var description: String {
        switch self {
        case .noAdapterFound: return "No adapter found"
        case .notConnectedToVehicle: return "Not connected to vehicle"
        }
    }
}


//enum OBDDevices: CaseIterable {
//    case carlyOBD
//    case mockOBD
//    case blueDriver
//
//    var properties: DeviceInfo {
//        switch self {
//        case .carlyOBD:
//            return DeviceInfo(id: UUID(uuidString: "5B6EE3F4-2FCA-CE45-6AE7-8D7390E64D6D") ?? UUID(), deviceName: "Carly", serviceUUID: "FFE0")
//
//        case .blueDriver:
//            return DeviceInfo(id: UUID(uuidString: "5B6EE3F4-2FCA-CE45-6AE7-8D7390E64D61") ?? UUID(), deviceName: "BlueDriver")
//        case .mockOBD:
//            return DeviceInfo(id: UUID(uuidString: "5B6EE3F4-2FCA-CE45-6AE7-8D7390E64A34") ?? UUID(), deviceName: "MockOBD")
//        }
//    }
//}

