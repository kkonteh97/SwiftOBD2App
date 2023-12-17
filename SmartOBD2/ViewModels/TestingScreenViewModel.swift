//
//  CarScreenViewModel.swift
//  SmartOBD2
//
//  Created by kemo konteh on 9/1/23.
//

import Foundation
import Combine
import CoreBluetooth

class TestingScreenViewModel: ObservableObject {

    let obdService: OBDService
    let garage: Garage
    private var cancellables = Set<AnyCancellable>()

    @Published var command: String = ""
    @Published var currentVehicle: Vehicle?
    @Published var isRequestingPids = false
    @Published var lastMessageID: String = ""
    @Published var peripherals: [Peripheral] = []

    @Published var connectPeripheral: CBPeripheralProtocol?

    init(_ obdService: OBDService, _ garage: Garage) {
        self.obdService = obdService
        self.garage = garage
        garage.$currentVehicle
            .sink { currentVehicle in
                self.currentVehicle = currentVehicle
            }
            .store(in: &cancellables)

        obdService.elm327.bleManager.$foundPeripherals
            .sink { peripherals in
                self.peripherals = peripherals
            }
            .store(in: &cancellables)

    }

    func sendMessage() async throws -> [String] {
        return try await obdService.elm327.sendMessageAsync(command, withTimeoutSecs: 5)
    }

    func startScanning() {
        obdService.elm327.bleManager.startScanning()
    }

    func connect(to peripheral: Peripheral) {
        Task {
            do {
                let connectedPeripheral = try await obdService.connect(to: peripheral)
                print("Connected to to ", connectedPeripheral.name ?? "No Name")
//                let services = try await obdService.elm327.bleManager.discoverServicesAsync(for: connectedPeripheral)
//                for service in services {
//                    print(service)
//                    let characteristics = try await obdService.elm327.bleManager.discoverCharacteristicsAsync(connectedPeripheral, for: service)
//                    for characteristic in characteristics {
//                        print(characteristic)
////                        if characteristic.uuid.uuidString == "FFF1" {
////                            let data = try await testCharacteristic(characteristic)
////                            print("data ", data)
////                        }
//                    }
//                }

                DispatchQueue.main.async {
                    self.connectPeripheral = connectedPeripheral
                }

            } catch {
                print(error.localizedDescription)
            }
        }
    }

    func testCharacteristic(_ characteristic: CBCharacteristic) async throws -> String {
        let data = try await obdService.elm327.bleManager.sendMessageAsync("ATZ", characteristic: characteristic)
        print("here ", data)
        return data.joined(separator: " ")
    }

    func requestPid(_ command: OBDCommand) {
        guard !isRequestingPids else {
            return
        }
        isRequestingPids = true
        Task {
            do {
                let messages = try await obdService.elm327.requestPIDs([command])
                guard !messages.isEmpty else {
                    return
                }
                guard let data = messages[0].data else {
                    return
                }
                print(data.compactMap { String(format: "%02X", $0) }.joined(separator: " "))
                let decodedValue = command.properties.decoder.decode(data: data[1...])
                switch decodedValue {
                    //            case .measurementMonitor(let measurement):
                    //                print(measurement.tests)
                case .measurementResult(let status):
                    print(status.value)
                case .stringResult(let status):
                    print(status)

                case .statusResult(let status):
                    print(status)

                default :
                    print("Not a measurement monitor")
                }
                DispatchQueue.main.async {
                    self.isRequestingPids = false
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}
