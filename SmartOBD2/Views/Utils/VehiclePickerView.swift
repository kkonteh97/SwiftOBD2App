//
//  VehiclePickerView.swift
//  SmartOBD2
//
//  Created by kemo konteh on 9/8/23.
//

import SwiftUI

class VehiclePickerViewModel: ObservableObject {
    var carData: [Manufacturer] = []
    let garage: Garage

    init(garage: Garage) {
        self.garage = garage
        loadGarageVehicles()
    }

    private func loadGarageVehicles() {
        do {
            let url = Bundle.main.url(forResource: "Cars", withExtension: "json")!
            let data = try Data(contentsOf: url)
            self.carData = try JSONDecoder().decode([Manufacturer].self, from: data)
        } catch {
            print("error loading vehicles")
        }
    }

    func addVehicle(make: String, model: String, year: String,
                    vin: String = "", obdinfo: OBDInfo? = nil) {
        garage.addVehicle(make: make, model: model, year: year)
    }
}

struct VehiclePickerView: View {
    @ObservedObject var viewModel = VehiclePickerViewModel(garage: Garage())
    @State var selectedYear = -1
    @State var selectedModel = -1 {
        didSet {
            selectedYear = -1
        }
    }

    @State var selectedManufacturer = -1 {
        didSet {
            selectedModel = -1
            selectedYear = -1
        }
    }

    var models: [Model] {
        return (0 ..< viewModel.carData.count).contains(selectedManufacturer) ? viewModel.carData[selectedManufacturer].models : []
    }

    var years: [Int] {
        return (0 ..< models.count).contains(selectedModel) ? models[selectedModel].years : []
    }

    var body: some View {
        HStack {
            Picker(selection: $selectedManufacturer, label: Text("Brand")) {
                Text("None")
                    .tag(-1)

                ForEach(0 ..< viewModel.carData.count, id: \.self) { carIndex in
                    Text(self.viewModel.carData[carIndex].make)
                        .tag(carIndex)
                }
            }
            .pickerStyle(WheelPickerStyle())

            if !models.isEmpty {
                Picker(selection: $selectedModel, label: Text("Model")) {
                    Text("None")
                        .tag(-1)

                    ForEach(0 ..< models.count, id: \.self) { modelIndex in
                        Text(models[modelIndex].name)
                            .tag(modelIndex)
                    }
                }
                .pickerStyle(WheelPickerStyle())
            }

            if !years.isEmpty {
                Picker(selection: $selectedYear, label: Text("Year")) {
                    Text("None")
                        .tag(-1)

                    ForEach(0 ..< years.count, id: \.self) { yearIndex in
                        Text("\(years[yearIndex])")
                            .tag(yearIndex)
                    }
                }
                .pickerStyle(WheelPickerStyle())
            }
        }

        if selectedYear != -1 && selectedModel != -1 && selectedManufacturer != -1 {
            Button(action: {
                viewModel.addVehicle(
                    make: viewModel.carData[selectedManufacturer].make,
                    model: models[selectedModel].name,
                    year: String(years[selectedYear])
                )
            }) {
                Text("Add")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
    }
}

#Preview {
    VehiclePickerView()
}
