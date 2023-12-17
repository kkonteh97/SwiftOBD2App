//
//  GarageViewModel.swift
//  SMARTOBD2
//
//  Created by kemo konteh on 10/5/23.
//

import Foundation
import Combine

class GarageViewModel: ObservableObject {
    @Published var garage: Garage
    @Published var currentVehicle: Vehicle?
    @Published var garageVehicles: [Vehicle] = []
    let obdService: OBDService

    private var cancellables = Set<AnyCancellable>()

    init(_ obdService: OBDService,_ garage: Garage) {
        self.obdService = obdService
        self.garage = garage

        garage.$garageVehicles
            .receive(on: DispatchQueue.main)
            .assign(to: \.garageVehicles, on: self)
            .store(in: &cancellables)

        garage.$currentVehicle
            .sink { currentVehicle in
                self.currentVehicle = currentVehicle
            }
            .store(in: &cancellables)
    }

    func setCurrentVehicle(by id: Int) {
        garage.setCurrentVehicle(by: id)
    }
    
    func deleteVehicle(_ vehicle: Vehicle) {
        garage.deleteVehicle(vehicle)
    }
}
