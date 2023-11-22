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

    private var cancellables = Set<AnyCancellable>()

    init(garage: Garage) {
        self.garage = garage
        garage.$garageVehicles
            .receive(on: DispatchQueue.main)
            .assign(to: \.garageVehicles, on: self)
            .store(in: &cancellables)
        
        garage.$currentVehicleId
                .sink { currentVehicleId in
                    self.currentVehicle = self.garage.garageVehicles.first(where: { $0.id == currentVehicleId } )
                }
                .store(in: &cancellables)
    }

    func deleteVehicle(_ vehicle: Vehicle) {
        garage.deleteVehicle(vehicle)
    }
}
