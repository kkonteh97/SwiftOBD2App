//
//  Garage.swift
//  SMARTOBD2
//
//  Created by kemo konteh on 9/30/23.
//

import SwiftUI
import Combine

struct Vehicle: Codable, Identifiable, Equatable {
    static func == (lhs: Vehicle, rhs: Vehicle) -> Bool {
        return lhs.id == rhs.id
    }
    let id: Int
    let make: String
    let model: String
    let year: String
    var obdinfo: OBDInfo = OBDInfo()

}

class Garage: ObservableObject {
    @Published var garageVehicles: [Vehicle] = []

    private var nextId = 1 // Initialize with the next integer ID

    var currentVehicleId: Int? {
        didSet {
            if let currentVehicleId = currentVehicleId {
                UserDefaults.standard.set(currentVehicleId, forKey: "currentCarId")
                currentVehicle = getVehicle(id: currentVehicleId)
            }
        }
    }

    @Published private(set) var currentVehicle: Vehicle?

    init () {
        // Load garageVehicles from UserDefaults
//        UserDefaults.standard.removeObject(forKey: "garageVehicles")
//        UserDefaults.standard.removeObject(forKey: "currentCarId")
        #if targetEnvironment(simulator)
        loadMockGarage()
        #else
        loadGarage()
        #endif
    }

    func loadGarage() {
        if let data = UserDefaults.standard.data(forKey: "garageVehicles"),
           let decodedVehicles = try? JSONDecoder().decode([Vehicle].self, from: data) {
            self.garageVehicles = decodedVehicles
        }

        // Determine the next available integer ID
        if let maxId = garageVehicles.map({ $0.id }).max() {
              self.nextId = maxId + 1
        }

        // Load currentVehicleId from UserDefaults
        self.currentVehicleId = UserDefaults.standard.integer(forKey: "currentCarId")
        currentVehicle = getVehicle(id: currentVehicleId ?? 0)
    }

    func loadMockGarage() {
        self.garageVehicles = [Vehicle(id: 1, make: "M-BMW", model: "X5", year: "2015", obdinfo: OBDInfo()),
                               Vehicle(id: 2, make: "M-Mercedes", model: "C300", year: "2018", obdinfo: OBDInfo()),
                               Vehicle(id: 3, make: "M-Toyota", model: "Camry", year: "2019", obdinfo: OBDInfo())]

        if let maxId = garageVehicles.map({ $0.id }).max() {
              self.nextId = maxId + 1
        }

        currentVehicle = garageVehicles[0]
    }

    func addVehicle(make: String, model: String, year: String, obdinfo: OBDInfo? = nil) {
        let vehicle = Vehicle(id: nextId, make: make, model: model, year: year, obdinfo: obdinfo ?? OBDInfo())
        garageVehicles.append(vehicle)
        nextId += 1
        saveGarageVehicles()
        currentVehicleId = vehicle.id
        print("Added vehicle \(vehicle)")
    }

    // set current vehicle by id
    func setCurrentVehicle(by id: Int) {
        currentVehicleId = id
    }

    func deleteVehicle(_ car: Vehicle) {
        garageVehicles.removeAll(where: { $0.id == car.id })
        if car.id == currentVehicleId { // check if the deleted car was the current one
            currentVehicleId = garageVehicles.first?.id // make the first car in the garage as the current car
        }
        saveGarageVehicles()
    }

    func updateVehicle(_ vehicle: Vehicle) {
        if let index = garageVehicles.firstIndex(where: { $0.id == vehicle.id }) {
            garageVehicles[index] = vehicle
        }
        saveGarageVehicles()
    }

    // get vehicle by id from garageVehicles
    func getVehicle(id: Int) -> Vehicle? {
        return garageVehicles.first(where: { $0.id == id })
    }

    func saveGarageVehicles() {
        if let encodedData = try? JSONEncoder().encode(garageVehicles) {
            UserDefaults.standard.set(encodedData, forKey: "garageVehicles")
        }
    }

    func switchToDemoMode(_ isDemoMode: Bool) {
        // put garage in demo mode
        switch isDemoMode {
        case true:
            loadMockGarage()
        case false:
            loadGarage()
        }
    }
}
