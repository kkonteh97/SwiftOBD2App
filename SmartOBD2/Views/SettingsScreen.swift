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
        HStack {

        Text("OBD Protocol: ")
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        
            Picker("Select Protocol", selection: $selectedProtocol) {
                ForEach(PROTOCOL.asArray, id: \.self) { protocolItem in
                    Text(protocolItem.description).tag(protocolItem)
                }
            }
        }
    }
}


extension Color {
    static let darkStart = Color(red: 50 / 255, green: 60 / 255, blue: 65 / 255)
    static let darkEnd = Color(red: 25 / 255, green: 25 / 255, blue: 30 / 255)
    static let lightStart = Color(red: 240 / 255, green: 240 / 255, blue: 246 / 255)
    static let lightEnd = Color(red: 120 / 255, green: 120 / 255, blue: 123 / 255)
    
    static let automotivePrimary = Color(red: 27 / 255, green: 109 / 255, blue: 207 / 255)
    static let automotiveSecondary = Color(red: 241 / 255, green: 143 / 255, blue: 1 / 255)
    static let automotiveAccent = Color(red: 228 / 255, green: 57 / 255, blue: 60 / 255)
    static let automotiveBackground = Color(red: 245 / 255, green: 245 / 255, blue: 245 / 255)
    
    static func startColor(for colorScheme: ColorScheme) -> Color {
        return colorScheme == .dark ? .darkStart : .lightStart
    }

    static func endColor(for colorScheme: ColorScheme) -> Color {
        return colorScheme == .dark ? .darkEnd : .lightEnd
    }
}

struct SettingsScreen: View {
    @ObservedObject var viewModel: SettingsScreenViewModel
    @State private var setupOrder: [SetupStep] = [.ATD, .ATZ, .ATL0, .ATE0, .ATH1, .ATAT1, .ATRV, .ATDPN]
    @State private var isSetupOrderPresented = false
    @State private var isVehicleModelPresented = false
    
    var body: some View {
        VStack {
            ScrollView(.vertical, showsIndicators: false){
                VStack {
                    bluetoothSection
                    pidSection
                    garageSection
                    elmSection
                
                }
            }
            .navigationBarTitle(Text("Settings"), displayMode: .automatic)
            .padding()
            
        }
    }
    
    @State private var isLoading = false
    
    private var pidSection: some View {
        GroupBox(label: SettingsLabelView(labelText: "pids", labelImage: "wifi.circle")) {
            
            Button {
                let pids = viewModel.obdInfo.ecuData.first?.value
                Task {
                    do {
                        try await viewModel.elm327.requestPIDs(pids: pids!)
                    }
                }
                
            } label: {
                RoundedRectangle(cornerRadius: 40)
                .fill(LinearGradient(isLoading  ? Color.darkEnd : Color.automotivePrimary, isLoading  ? Color.darkStart : Color.darkEnd))
                    .frame(width: 90, height: 90)

                    .overlay {

                            VStack {
                                Image(systemName: "car.front.waves.up.fill")
                                    .font(.system(size: 35))
                                    .foregroundColor(.gray)
                                Text("Resquest Pids")
                
                    }
                
            }
            }
        }
    }
    

    // Bluetooth Section
    private var bluetoothSection: some View {
        HStack {
            GroupBox(label: SettingsLabelView(labelText: "Bluetooth", labelImage: "wifi.circle")) {
                Divider().padding(.vertical, 4)
                VStack {
                    Text("\(viewModel.elmAdapter?.name ?? "")")
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .center)


            Button {
                let impactLight = UIImpactFeedbackGenerator(style: .medium)
                impactLight.impactOccurred()
                self.isLoading = true
                Task {
                    do {
                        try await viewModel.setupAdapter(setupOrder: setupOrder)
                    } catch {
                        print("Error setting up adapter: \(error.localizedDescription)")
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.isLoading = false

                }
            } label: {
                    RoundedRectangle(cornerRadius: 60)
                    .fill(LinearGradient(isLoading  ? Color.darkEnd : Color.darkStart, isLoading  ? Color.darkStart : Color.darkEnd))
                        .frame(width: 120, height: 120)
                        .shadow(color: isLoading ? Color.darkStart : Color.darkEnd, radius: 10,  x: isLoading  ? -5 : 10, y: isLoading  ? -5 : 10)
                        .shadow(color: isLoading ? Color.darkEnd : Color.darkStart, radius: 10, x: isLoading  ? 10 : -5, y: isLoading  ? 10 : -5)
                        .overlay {
                            if isLoading {
                                ProgressView()
                            }  else {
                                VStack {
                                    Image(systemName: "car.front.waves.up.fill")
                                        .font(.system(size: 35))
                                        .foregroundColor(.gray)
                                    Text("Connect")
                                }
                        }
                    
                }
                
            }
            .frame(maxWidth: 100, alignment: .center)
        }
        .padding()

    }
    
    @State private var isExpanded = false
    @State private var addVehicle = false
    @AppStorage("selectedCarIndex") var selectedCarIndex: Int = 0
    
    

    // Garage Section
    private var garageSection: some View {
        GroupBox(label: SettingsLabelView(labelText: "Garage", labelImage: "car.side")) {
            Divider().padding(.vertical, 4)
            
            VStack { // Wrap the content in a VStack
                HStack {
//                    Text(viewModel.garageVehicles[selectedCarIndex].make)
//                    Spacer()
//                    Text(viewModel.garageVehicles[selectedCarIndex].model)
//                    Spacer()
//                    Text(viewModel.garageVehicles[selectedCarIndex].year)
                }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(LinearGradient(Color.darkStart,Color.darkEnd))
                                .shadow(color: Color.darkEnd, radius: 5, x: -3, y: -3)
                                .shadow(color: Color.darkStart, radius: 5, x: 3, y: 3))
                
                VStack {
                    
                    if isExpanded {
                        VStack {
                            ForEach(viewModel.garageVehicles.filter({ $0.id != viewModel.garageVehicles[selectedCarIndex].id })) { car in
                                HStack {
                                    Text(car.make)
                                    Spacer()
                                    Text(car.model)
                                    Spacer()
                                    Text(car.year)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .onTapGesture {
                                    if selectedCarIndex != viewModel.garageVehicles.firstIndex(where: { $0.id == car.id }) {
                                       withAnimation {
                                           selectedCarIndex = viewModel.garageVehicles.firstIndex(where: { $0.id == car.id })!
                                       }
                                   }
                                
                                }
                            }
                    
                            if addVehicle {
                                VehiclePickerView(viewModel: viewModel)
                            }
                            
                            Button {
                                addVehicle.toggle()
                            } label: {
                                Text("Add Vehicle")
                            }
                            .buttonStyle(ShadowButtonStyle())

                            
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .offset(y: isExpanded ? 0 : -100) // Slide down the content
                .opacity(isExpanded ? 1 : 0) // Fade in the content
                Spacer()

               Button(action: {
                   withAnimation(.easeInOut(duration: 0.3)) {
                       
                       isExpanded.toggle()
                   }
               }, label: {
                   Image(systemName: "chevron.down.circle")
                       .font(.title)
                      .rotationEffect(.degrees(isExpanded ? 180 : 0))
                      .foregroundColor(.gray)
                   
               })
               .padding(.top, 40)
               }
        
        }
    }
    
    
    // ELM Section
    private var elmSection: some View {
        GroupBox(label: SettingsLabelView(labelText: "ELM", labelImage: "info.circle")) {
            Divider().padding(.vertical, 4)

            ProtocolPicker(selectedProtocol: $viewModel.selectedProtocol)
            
            HStack {
                Button("Setup Order") {
                    isSetupOrderPresented.toggle()
                }
                .buttonStyle(ShadowButtonStyle())
                .sheet(isPresented: $isSetupOrderPresented) {
                    SetupOrderModal(isModalPresented: $isSetupOrderPresented, setupOrder: $setupOrder)
                }
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



struct SettingsScreen_Previews: PreviewProvider {
    static var previews: some View {
        let previewViewModel = SettingsScreenViewModel(elm327: ELM327(bleManager: BLEManager()), bleManager: BLEManager())
        return SettingsScreen(viewModel: previewViewModel)
    }
}
