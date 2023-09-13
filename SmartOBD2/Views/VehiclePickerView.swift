//
//  VehiclePickerView.swift
//  SmartOBD2
//
//  Created by kemo konteh on 9/8/23.
//

import SwiftUI

struct VehiclePickerView: View {
    @ObservedObject var viewModel: SettingsScreenViewModel
    
    var body: some View {
        HStack {
            Picker(selection: $viewModel.selectedManufacturer, label: Text("Brand")) {
                Text("None")
                    .tag(-1)
                
                ForEach(0 ..< viewModel.carData.count, id: \.self) { carIndex in
                    Text(self.viewModel.carData[carIndex].make)
                        .tag(carIndex)
                }
            }
            .pickerStyle(WheelPickerStyle())
            
            if !viewModel.models.isEmpty {
                Picker(selection: $viewModel.selectedModel, label: Text("Model")) {
                    Text("None")
                        .tag(-1)
                    
                    ForEach(0 ..< viewModel.models.count, id: \.self) { modelIndex in
                        Text(self.viewModel.models[modelIndex].name)
                            .tag(modelIndex)
                    }
                }
                .pickerStyle(WheelPickerStyle())
            }
            
            if !viewModel.years.isEmpty {
                Picker(selection: $viewModel.selectedYear, label: Text("Year")) {
                    Text("None")
                        .tag(-1)
                    
                    ForEach(0 ..< viewModel.years.count, id: \.self) { yearIndex in
                        Text("\(self.viewModel.years[yearIndex])")
                            .tag(yearIndex)
                    }
                }
                .pickerStyle(WheelPickerStyle())
            }
        }
        
        if viewModel.selectedYear != -1 && viewModel.selectedModel != -1 && viewModel.selectedManufacturer != -1 {
            Button(action: {
                viewModel.addVehicle()
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
    VehiclePickerView(viewModel: SettingsScreenViewModel(elm327: ELM327(bleManager: BLEManager()), bleManager: BLEManager()))
}
