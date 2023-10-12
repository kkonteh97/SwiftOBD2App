//
//  LiveDataViewModel.swift
//  SMARTOBD2
//
//  Created by kemo konteh on 10/5/23.
//

import Foundation
import Combine

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
    }

    var cancellables = Set<AnyCancellable>()

    func addPIDToRequest(_ pid: OBDCommand) {
        if !pidsToRequest.contains(pid) {
            print("added")
            pidsToRequest.append(pid)
        }
    }

    @Published var pidsToRequest: [OBDCommand] = [OBDCommand.speed, OBDCommand.rpm]

    @Published var data: [OBDCommand: Measurement<Unit>?] = [:]

    func startRequestingPIDs() {
        guard !isRequestingPids else {
            return
        }
        isRequestingPids = true
        Task {
            while isRequestingPids {
                for pid in pidsToRequest {
                    guard let decodedPid = await obdService.elm327.requestPIDs(pid) else {
                        continue
                    }
                    DispatchQueue.main.async {
                        self.data[pid] = decodedPid
                    }
                }
            }
        }
    }
}
