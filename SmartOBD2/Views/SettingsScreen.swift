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

struct RoundedRectangleStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(LinearGradient(Color.darkStart, Color.darkEnd))
                    .shadow(color: Color.darkEnd, radius: 5, x: -3, y: -3)
                    .shadow(color: Color.darkStart, radius: 5, x: 3, y: 3)
            )
    }
}

<<<<<<< HEAD
<<<<<<< HEAD
struct DraggableContentView: View {
    @Binding var isExpanded: Bool

    var body: some View {
        VStack {
            // Your content goes here
            Text("Draggable Content")
        }
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(20)
        .padding()
        .offset(y: isExpanded ? 0 : UIScreen.main.bounds.height)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if value.translation.height > 0 {
                        // Allow dragging only in the upward direction
                        isExpanded = true
                    }
                }
                .onEnded { value in
                    let dragThreshold: CGFloat = 100 // Adjust this threshold as needed
                    if value.translation.height > dragThreshold {
                        // If dragged beyond the threshold, expand the view
                        withAnimation {
                            isExpanded = true
                        }
                    } else {
                        // Otherwise, reset to the initial position
                        withAnimation {
                            isExpanded = false
                        }
                    }
                }
        )
    }
}

=======
>>>>>>> main
=======


>>>>>>> parent of 576eaca (Revert "dropped version down to ios 15")
struct SettingsScreen: View {
    @ObservedObject var viewModel: SettingsScreenViewModel
    @State private var setupOrder: [SetupStep] = [.ATD, .ATZ, .ATL0, .ATE0, .ATH1, .ATAT1, .ATRV, .ATDPN]
    @State private var selectedPIDValues: [OBDCommand: String] = [:]
    @State private var selectedPID: OBDCommand?

    @State private var isSetupOrderPresented = false
    @State private var isVehicleModelPresented = false
    @State private var isExpandedCarInfo = false
    @State private var isExpandedOtherCars = false

    @State private var isLoading = false
<<<<<<< HEAD
<<<<<<< HEAD
    @State private var addVehicle = false

    @AppStorage("selectedCarIndex") var selectedCarIndex = 0

    @State private var isExpanded = false

    // Computed properties
    var isConnected: Bool {
        viewModel.elm327.bleManager.connected
    }

    var selectedCar: GarageVehicle? {
        guard selectedCarIndex < viewModel.garageVehicles.count,
              !viewModel.garageVehicles.isEmpty
        else {
            selectedCarIndex = 0
            return nil
        }
        return viewModel.garageVehicles[selectedCarIndex]
    }

    var garageVehicles: [GarageVehicle] {
        viewModel.garageVehicles
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                bluetoothSection

                garageSection
                elmSection

            }
            .padding(.horizontal, 20)
        }
        .ignoresSafeArea(.all, edges: .bottom)
    }

// MARK: Bluetooth Section

=======
=======
    @State private var selectedPIDValues: [OBDCommand: String] = [:]
    @State private var selectedPID: OBDCommand? = nil
>>>>>>> parent of 576eaca (Revert "dropped version down to ios 15")
    
    private var pidSection: some View {
        GroupBox(label: SettingsLabelView(labelText: "pids", labelImage: "wifi.circle")) {
            Divider().padding(.vertical, 4)
            // Supported PIDs
            Text("Supported PIDs")
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack {
                if let supportedPIDs = viewModel.obdInfo.supportedPIDs {
                    ForEach(supportedPIDs, id: \.self) { pid in
                        HStack {
                            
                            Text(pid.description)
                                .font(.caption)
                                .padding()
                            
                                .onTapGesture {
                                    Task {
                                        await viewModel.requestPID(pid: pid)
                                    }
                                }
                            if let pidData = viewModel.pidData[pid] {
                                Text("\(pidData.value) \(pidData.unit)")
                                    .font(.caption)
                                    .padding()
                                
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(LinearGradient(Color.darkStart,Color.darkEnd))
                                .shadow(color: Color.darkEnd, radius: 5, x: -3, y: -3)
                                .shadow(color: Color.darkStart, radius: 5, x: 3, y: 3))
                        }
                       
                    }
                }
            }
            .frame(minHeight: 200)
    }
    
    
    
    // Bluetooth Section
>>>>>>> main
    private var bluetoothSection: some View {
        VStack {
            GroupBox(label: SettingsLabelView(labelText: "Adapter", labelImage: "wifi.circle")) {
                Divider().padding(.vertical, 4)

                VStack {
                    Text("\(isConnected ? "Connected": "Not Connect")")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Device: \(viewModel.elmAdapter?.name ?? "")")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer()
                }
            }
            .padding()
        }
        .padding()

    }

// MARK: Garage Section

    private var garageSection: some View {
        GroupBox(label: SettingsLabelView(labelText: "Garage", labelImage: "car.side")) {
            Divider().padding(.vertical, 4)

            VStack {
                carDetailsView()
                if isExpandedCarInfo {
                    Divider().padding(.vertical, 4)
                    carInfoExpandedView()
                }
                if isExpandedOtherCars {
                    Divider().padding(.vertical, 4)
                    otherVehiclesView()
                }
                Spacer()
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isExpandedOtherCars.toggle()
                    }
                }, label: {
                    Image(systemName: "chevron.down.circle")
                        .font(.title)
                        .rotationEffect(.degrees(isExpandedOtherCars ? 180 : 0))
                        .foregroundColor(.gray)

                })
                .padding(.top, 40)
            }
        }
    }
<<<<<<< HEAD
=======
    
<<<<<<< HEAD
    @State private var selectedPIDValues: [OBDCommand: String] = [:]
    @State private var selectedPID: OBDCommand? = nil
>>>>>>> main

    private func carDetailsView() -> some View {
        VStack(spacing: 20) {
            HStack {
                if let car = selectedCar {
                    Text(car.make)
                    Spacer()
                    Text(car.model)
                    Spacer()
                    Text(car.year)
                    Spacer()

                    Image(systemName: isExpandedCarInfo ? "chevron.up" : "chevron.down")
                        .resizable()
                        .frame(width: 17, height: 10)
                        .foregroundColor(.gray)
                        .onTapGesture {
                            withAnimation(.spring()) {
                                isExpandedCarInfo.toggle()
                            }
                        }
                    }
                }
                    .frame(maxWidth: .infinity, alignment: .leading)
                Divider().padding(.vertical, 4)

                connectButton()

        }
        .modifier(RoundedRectangleStyle())

    }

    private func carInfoExpandedView() -> some View {
        VStack {
            // Supported PIDs
            Text("Supported PIDs")
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)

            if let supportedPIDs = viewModel.garageVehicles[selectedCarIndex].obdinfo?.supportedPIDs {
                List(supportedPIDs, id: \.self) { pid in
                    HStack {

                        Text(pid.description)
                            .font(.caption)
                            .padding()

                        if let pidData = viewModel.pidData[pid] {
                            Text("\(pidData.value) \(pidData.unit)")
                                .font(.caption)
                                .padding()

                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(LinearGradient(Color.darkStart, Color.darkEnd))
                            .shadow(color: Color.darkEnd, radius: 5, x: -3, y: -3)
                            .shadow(color: Color.darkStart, radius: 5, x: 3, y: 3))
                    .onTapGesture {
                        viewModel.startRequestingPID(pid: pid)
                    }
                }
                .frame(minHeight: 300)
                .listStyle(PlainListStyle())
            }
        }
        .offset(y: isExpandedCarInfo ? 0 : -100) // Slide down the content
        .opacity(isExpandedCarInfo ? 1 : 0) // Fade in the content
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func otherVehiclesView() -> some View {
        VStack {
            ForEach(garageVehicles) { car in
                HStack {
                    Text(car.make)
                    Spacer()
                    Text(car.model)
                    Spacer()
                    Text(car.year)
                    Spacer()
                    Button {
                        viewModel.deleteVehicle(car)
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .onTapGesture {
                    if selectedCarIndex != garageVehicles.firstIndex(where: { $0.id == car.id }) {
                        withAnimation {
                            selectedCarIndex = garageVehicles.firstIndex(where: { $0.id == car.id })!
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
        .offset(y: isExpandedOtherCars ? 0 : -100) // Slide down the content
        .opacity(isExpandedOtherCars ? 1 : 0) // Fade in the content
    }

    private func connectButton() -> some View {
        Button {
            let impactLight = UIImpactFeedbackGenerator(style: .medium)
            impactLight.impactOccurred()
            self.isLoading = true
            Task {
                do {
                    try await viewModel.setupAdapter(setupOrder: setupOrder)
                    // remove when done
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.isLoading = false
                    }
                } catch {
                    print("Error setting up adapter: \(error.localizedDescription)")
                }
            }
        } label: {
            VStack {
                if isLoading {
                    ProgressView()
                } else {
                    Text(viewModel.elm327.bleManager.connectionState == .connectedToVehicle ?
                         "Connected To Vehicle" : "Initialize Vehicle")
                        .font(.headline)

                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(LinearGradient(Color.darkStart, Color.darkEnd))
                    .shadow(color: Color.darkEnd, radius: 5, x: -3, y: -3)
                    .shadow(color: Color.darkStart, radius: 5, x: 3, y: 3))
        }
    }

// MARK: ELM Section
=======
>>>>>>> parent of 576eaca (Revert "dropped version down to ios 15")

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
        let previewViewModel = SettingsScreenViewModel(elm327: ELM327(bleManager: BLEManager()))
        return SettingsScreen(viewModel: previewViewModel)
    }
}
