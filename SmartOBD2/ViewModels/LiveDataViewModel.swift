//
//  LiveDataViewModel.swift
//  SMARTOBD2
//
//  Created by kemo konteh on 10/5/23.
//

import Foundation
import Combine

struct PidData {
    var pid: OBDCommand
    var value: OBDDecodeResult
}

struct DataItem {
    let command: OBDCommand
    var measurement: OBDDecodeResult?
}

enum OBDDecodeResult {
    case doubleResult(Double)
    case stringResult(String)
    case statusResult(Status)
    case measurementResult(Measurement<Unit>)
    case noResult
}

class LiveDataViewModel: ObservableObject {
    let obdService: OBDService
    let garage: Garage

    @Published var currentVehicle: GarageVehicle?


    private var isRequestingPids = false

    init(obdService: OBDService, garage: Garage) {
        self.obdService = obdService
        self.garage = garage
        garage.$currentVehicleId
                .sink { currentVehicleId in
                    self.currentVehicle = self.garage.garageVehicles.first(where: { $0.id == currentVehicleId })
                }
                .store(in: &cancellables)

        updateDataItems()
    }

    var cancellables = Set<AnyCancellable>()

    func addPIDToRequest(_ pid: OBDCommand) {
        if !pidsToRequest.contains(pid) {
            pidsToRequest.append(pid)
        } else {
            pidsToRequest.removeAll(where: { $0 == pid })
        }
    }

    @Published var pidsToRequest: [OBDCommand] = [ .coolantTemp, .rpm, .speed] {
            didSet {
                updateDataItems()
            }
        }

    @Published var data: [DataItem] = []

    func startRequestingPIDs() {
        guard !isRequestingPids else {
            return
        }
        isRequestingPids = true
        Task {
            while isRequestingPids {
                guard let decodedValues = await obdService.elm327.requestPIDs(pidsToRequest) else {
                    continue
                }
                DispatchQueue.main.async {
                    self.data = decodedValues.map {
                        DataItem(command: $0.pid, measurement: $0.value)
                    }
                }
            }
        }
    }

    private func updateDataItems() {
            // Remove items from data where their commands are not in pidsToRequest
            data.removeAll(where: { !pidsToRequest.contains($0.command) })

            // Add items to data for new pids in pidsToRequest
            for pid in pidsToRequest {
                if !data.contains(where: { $0.command == pid }) {
                    data.append(DataItem(command: pid, measurement: nil))
                }
            }
        }

    func decodeMeasurementToString(_ measurement: OBDDecodeResult?) -> String {
        guard let measurement = measurement else {
            return "N/A"
        }
        switch measurement {
        case .doubleResult(let value):
            return String(describing: value)
        case .stringResult(let value):
            return value
        case .statusResult(let value):
            return String(describing: value)
        case .measurementResult(let value):
            return "\(value.value) \(value.unit.symbol)"
        case .noResult:
            return "No Result"
        }
    }
}
