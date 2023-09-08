//
//  SettingsScreen.swift
//  SmartOBD2
//
//  Created by kemo konteh on 8/13/23.
//

import SwiftUI
import CoreBluetooth






struct ProtocolPicker: View {
    @Binding var selectedProtocol: PROTOCOL
    
    var body: some View {
        Picker("Select Protocol", selection: $selectedProtocol) {
            ForEach(PROTOCOL.asArray, id: \.self) { protocolItem in
                Text(protocolItem.description).tag(protocolItem)
            }
        }
    }
}



struct SettingsScreen: View {
    @ObservedObject var viewModel: SettingsScreenViewModel
    @State private var setupOrder: [SetupStep] = [.ATD, .ATZ, .ATL0, .ATE0, .ATH1, .ATAT1, .ATRV, .ATDPN]
    @State private var isSetupOrderPresented = false
    @State private var isVehicleModelPresented = false
    
    var body: some View {
        NavigationView{
            ScrollView(.vertical, showsIndicators: false){
                VStack {
                    bluetoothSection
                    garageSection
                    elmSection
                    
                }
            }
            .navigationBarTitle(Text("Settings"), displayMode: .automatic)
            .padding()
            
        }
    }
    
    // Bluetooth Section
    private var bluetoothSection: some View {
        GroupBox(label: SettingsLabelView(labelText: "Bluetooth", labelImage: "wifi.circle")) {
            Divider().padding(.vertical, 4)
            AdapterInfoView(viewModel: viewModel)
                .padding()
        }
    }
    
    // Garage Section
    private var garageSection: some View {
        GroupBox(label: SettingsLabelView(labelText: "Garage", labelImage: "car.side")) {
            Divider().padding(.vertical, 4)
            HStack {
                Text(viewModel.garageVehicles[0].make)
                Text(viewModel.garageVehicles[0].model)
                Text(viewModel.garageVehicles[0].year)
                Spacer()
                Button(action: {
                }, label: {
                    Image(systemName: "ellipsis")
                        .font(.largeTitle)
                })
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(LinearGradient(Color.darkStart))
                    .shadow(color: Color.darkEnd, radius: 5, x: -3, y: -3)
                    .shadow(color: Color.darkStart, radius: 5, x: 3, y: 3)
                
            )
        }
    }
    
    
    // ELM Section
    private var elmSection: some View {
        GroupBox(label: SettingsLabelView(labelText: "ELM", labelImage: "info.circle")) {
            Divider().padding(.vertical, 4)
            HStack {
                Text("OBD Protocol: ")
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                ProtocolPicker(selectedProtocol: $viewModel.selectedProtocol)
            }
            
            HStack {
                Button("Setup Order") {
                    isSetupOrderPresented.toggle()
                }
                .buttonStyle(ShadowButtonStyle())
                .sheet(isPresented: $isSetupOrderPresented) {
                    SetupOrderModal(isModalPresented: $isSetupOrderPresented, setupOrder: $setupOrder)
                }
                Button("Start") {
                    Task {
                        do {
                            try await viewModel.setupAdapter(setupOrder: setupOrder)
                        } catch {
                            print("Error setting up adapter: \(error.localizedDescription)")
                        }
                    }
                }
                .buttonStyle(ShadowButtonStyle())
            }
            
            // Supported PIDs
            Text("Supported PIDs")
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVStack(alignment: .leading) {
                ForEach(viewModel.obdInfo.ecuData.keys.sorted(), id: \.self) { header in
                    if let supportedPIDs = viewModel.obdInfo.ecuData[header] {
                        Section {
                            VStack(alignment: .leading) {
                                Section(header:
                                            Text("ECU Header: \(header)")
                                    .font(.subheadline)
                                ) {
                                    ForEach(supportedPIDs, id: \.self) { pid in
                                        Text(pid.descriptions)
                                            .font(.subheadline)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

struct ShadowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(width: 170, height: 50)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(LinearGradient(Color.darkStart))
                    .shadow(color: Color.darkEnd, radius: 5, x: -3, y: -3)
                    .shadow(color: Color.darkStart, radius: 5, x: 3, y: 3)
            )
    }
}

struct BlueButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(width: 170, height: 50)
            .background(Color.blue)
            .cornerRadius(10)
    }
}

struct AdapterInfoView: View {
    var viewModel: SettingsScreenViewModel
    
    var body: some View {
        VStack {
            Text("Adapter: \(viewModel.elmAdapter?.name ?? "")")
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct VinInfoView: View {
    @ObservedObject var viewModel: SettingsScreenViewModel
    @Binding var isModalPresented: Bool
    
    @State private var addVehicle = false
    
    var body: some View {
        VStack {
            List {
                ForEach(viewModel.garageVehicles, id: \.id) { car in
                    HStack {
                        Text(car.make)
                        Text(car.model)
                        Text(car.year)
                    }
                }
            }
            
            if addVehicle {
                AddVehicleView(viewModel: viewModel)
            } else {
                Button {
                    addVehicle.toggle()
                } label: {
                    Text("Add Vehicle")
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}


struct AddVehicleView: View {
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



struct SettingsScreen_Previews: PreviewProvider {
    static var previews: some View {
        let previewViewModel = SettingsScreenViewModel(elm327: ELM327(bleManager: BLEManager()), bleManager: BLEManager())
        
        return SettingsScreen(viewModel: previewViewModel)
            .previewLayout(.sizeThatFits)

    }
}
