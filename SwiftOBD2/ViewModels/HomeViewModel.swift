//
//  HomeViewModel.swift
//  SMARTOBD2
//
//  Created by kemo konteh on 9/30/23.
//

import SwiftUI
import Combine

class HomeViewModel: ObservableObject {
    @Published var obdInfo = OBDInfo()

    @Published var vinInput = ""
    @Published var vinInfo: VINInfo?
    @Published var selectedProtocol: PROTOCOL = .NONE
    @Published var garage: Garage

    @Published var garageVehicles: [Vehicle] = []

//    @Published var currentVehicle: Vehicle?

    private var cancellables = Set<AnyCancellable>()

    let obdService: OBDService

    init(_ obdService: OBDService, _ garage: Garage) {
        self.obdService = obdService
        self.garage = garage

        garage.$garageVehicles
            .receive(on: DispatchQueue.main)
            .assign(to: \.garageVehicles, on: self)
            .store(in: &cancellables)
//
//        garage.$currentVehicleId
//                .sink { currentVehicleId in
//                    self.currentVehicle = self.garage.garageVehicles.first(where: { $0.id == currentVehicleId } )
//                }
//                .store(in: &cancellables)
    }
}
