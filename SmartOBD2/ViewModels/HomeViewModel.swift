//
//  HomeViewModel.swift
//  SMARTOBD2
//
//  Created by kemo konteh on 9/30/23.
//

import Foundation
import Combine

class HomeViewModel: ObservableObject {
    @Published var obdInfo = OBDInfo()

    @Published var vinInput = ""
    @Published var vinInfo: VINInfo?
    @Published var selectedProtocol: PROTOCOL = .NONE
    @Published var garage: Garage

    @Published var garageVehicles: [GarageVehicle] = []
    private var cancellables = Set<AnyCancellable>()

    let obdService: OBDService

    init(obdService: OBDService, garage: Garage) {
        self.obdService = obdService
        self.garage = garage

        garage.$garageVehicles
            .receive(on: DispatchQueue.main)
            .assign(to: \.garageVehicles, on: self)
            .store(in: &cancellables)
    }
}
