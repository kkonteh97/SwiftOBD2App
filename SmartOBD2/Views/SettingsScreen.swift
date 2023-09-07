//
//  SettingsScreen.swift
//  SmartOBD2
//
//  Created by kemo konteh on 8/13/23.
//

import SwiftUI
import CoreBluetooth


struct SettingsScreen: View {
    @ObservedObject var viewModel: SettingsScreenViewModel
    @State private var setupOrder: [SetupStep] = [.ATD, .ATZ, .ATL0, .ATE0, .ATH1, .ATAT1, .ATRV, .ATDPN]
    @State private var isModalPresented = false
    @State private var obdInfo: OBDInfo?
    @State private var isAnimating = false
    @State private var isOpen = false

    
    var body: some View {
        NavigationView {
            VStack {
                // Header Buttons
                HStack {
                    
                    Button("Change Setup Order") {
                        isModalPresented.toggle()
                    }
                    .buttonStyle(BlueButtonStyle())
                    .sheet(isPresented: $isModalPresented) {
                        SetupOrderModal(isModalPresented: $isModalPresented, setupOrder: $setupOrder)
                    }
                    
                    Button("Setup") {
                        Task {
                            do {
                                try await viewModel.setupAdapter(setupOrder: setupOrder)
                                isAnimating.toggle()
                            } catch {
                                print("Error setting up adapter: \(error.localizedDescription)")
                            }
                        }
                    }
                    .buttonStyle(BlueButtonStyle())
                    
                }
                
                TextField("VIN", text: $viewModel.vinInput)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                HStack {
                    Text("OBD Protocol: ")
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    ProtocolPicker(selectedProtocol: $viewModel.selectedProtocol)

                }
                VinInfoView(viewModel: viewModel)

                HStack {
                    NavigationLink(destination: Text("Hello")) {
                        AdapterInfoView(viewModel: viewModel)
                    }
                    .buttonStyle(BlueButtonStyle2())

                    
 
                }
                .frame(maxHeight: 200)
                
                // Supported PIDs
                Text("Supported PIDs")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                
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
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle()) // Specify the display mode
        
    }
    
}
struct ProtocolPicker: View {
    @Binding var selectedProtocol: PROTOCOL
    
    var body: some View {
        Picker("Select Protocol", selection: $selectedProtocol) {
            ForEach(PROTOCOL.asArray, id: \.self) { protocols in
                Text(protocols.description).tag(protocols)
            }
        }
    }
}
struct BlueButtonStyle2: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity, maxHeight: 200, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.blue, lineWidth: 2)
            }
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

struct Manufacturer: Codable {
    let make: String
    let models: [CarModel]
}

struct CarModel: Codable {
    let name: String
    let years: [Int]
}


//struct CarPickerView: View {
//    @State private var selectedMakeIndex = 0
//    @State private var selectedModelIndex = 0
//    @State private var selectedYearIndex = 0
//
//    // Load the JSON data
//    private let carData: [CarData] = {
//        if let fileURL = Bundle.main.url(forResource: "cars", withExtension: "json"),
//           let data = try? Data(contentsOf: fileURL),
//           let decodedData = try? JSONDecoder().decode([CarData].self, from: data) {
//            return decodedData
//        }
//        return []
//    }()
//
//    var body: some View {
//        VStack {
//            Picker("Select a Make", selection: $selectedMakeIndex) {
//                    ForEach(0..<carData.count) { index in
//                        Text(carData[index].make).tag(index)
//                    }
//                }
//                .pickerStyle(WheelPickerStyle())
//                .padding()
//
//            Picker("Select a Model", selection: $selectedModelIndex) {
//                ForEach(0..<carData[selectedMakeIndex].models.count) { index in
//                    Text(carData[selectedMakeIndex].models[index].name).tag(index)
//                }
//            }
//            .pickerStyle(WheelPickerStyle())
//            .padding()
//
//            Picker("Select a Year", selection: $selectedYearIndex) {
//                ForEach(0..<carData[selectedMakeIndex].models[selectedModelIndex].years.count) { index in
//                    Text("\(carData[selectedMakeIndex].models[selectedModelIndex].years[index])").tag(index)
//                }
//            }
//            .pickerStyle(WheelPickerStyle())
//            .padding()
//        }
//    }
//}
struct VinInfoView: View {
    var viewModel: SettingsScreenViewModel
    @State private var selectedMakeIndex = 0
    @State private var selectedModelIndex = 0
    @State private var selectedYearIndex = 0
    
    @ObservedObject private var model = ContentViewModel()
    
    var body: some View {
        HStack {
            Picker(selection: $model.selectedManufacturer, label: Text("Brand")) {
                ForEach(0 ..< model.carData.count, id: \.self) { carIndex in
                    Text(self.model.carData[carIndex].make)
                        .tag(carIndex)
                }
            }
            .pickerStyle(WheelPickerStyle())
            
            if !model.models.isEmpty {
                Picker(selection: $model.selectedModel, label: Text("Model")) {
                    ForEach(0 ..< model.models.count, id: \.self) { modelIndex in
                        Text(self.model.models[modelIndex].name)
                            .tag(modelIndex)
                    }
                }
                .pickerStyle(WheelPickerStyle())
            }
            
            if !model.years.isEmpty {
                Picker(selection: $model.selectedYear, label: Text("Year")) {
                    Text("None")
                        .tag(-1)
                    
                    ForEach(0 ..< model.years.count, id: \.self) { yearIndex in
                        Text("\(self.model.years[yearIndex])")
                            .tag(yearIndex)
                    }
                }
                .pickerStyle(WheelPickerStyle()) // Use the style you prefer
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.blue, lineWidth: 2)
        }
    }
}


class ContentViewModel: ObservableObject {
    // Load the JSON data
    let carData: [Manufacturer]
    
    @Published var selectedManufacturer = -1 {
        didSet {
            // reset the currently selected model to "None" when the manufacturer changes
            selectedModel = -1
            selectedYear = -1
        }
    }
    @Published var selectedModel = -1 {
        didSet {
            // reset the currently selected year to "None" when the model changes
            selectedYear = -1
        }
    }
    
    var models: [CarModel] {
        if (0 ..< carData.count).contains(selectedManufacturer) {
            return carData[selectedManufacturer].models
        }
        return []
    }
    
    @Published var selectedYear = -1
    var years: [Int] {
        if (0 ..< models.count).contains(selectedModel) {
            return models[selectedModel].years
        }
        return []
    }
    
    
    init() {
        let url = Bundle.main.url(forResource: "Cars", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        carData = try! JSONDecoder().decode([Manufacturer].self, from: data)
    }
}

struct SettingsScreen_Previews: PreviewProvider {
    static var previews: some View {
        SettingsScreen(viewModel: SettingsScreenViewModel(elm327: ELM327(bleManager: BLEManager()), bleManager: BLEManager()))
    }
}
