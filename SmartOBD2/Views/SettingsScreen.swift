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
//
//class SettingsScreenViewModel: ObservableObject {
//
//}
//
//struct SettingsScreen: View {
//    @ObservedObject var viewModel: SettingsScreenViewModel
//    @State private var setupOrder: [SetupStep] = [.ATD, .ATZ, .ATL0, .ATE0, .ATH1, .ATAT1, .ATRV, .ATDPN]
//    @State private var selectedPIDValues: [OBDCommand: String] = [:]
//    @State private var selectedPID: OBDCommand?
//
//    @State private var isSetupOrderPresented = false
//    @State private var isVehicleModelPresented = false
//    @State private var isExpandedCarInfo = false
//    @State private var isExpandedOtherCars = false
//
//    @State private var isLoading = false
//    @State private var addVehicle = false
//
//    @AppStorage("selectedCarIndex") var selectedCarIndex = 0
//    @State private var bottomSheetShown = false
//    @State private var isExpanded = false
//
//    // Computed properties
//    var isConnected: Bool {
//        viewModel.elm327.bleManager.connected
//    }
//
//    var selectedCar: GarageVehicle? {
//        guard selectedCarIndex < viewModel.garageVehicles.count,
//              !viewModel.garageVehicles.isEmpty
//        else {
//            selectedCarIndex = 0
//            return nil
//        }
//        return viewModel.garageVehicles[selectedCarIndex]
//    }
//
//    var garageVehicles: [GarageVehicle] {
//        viewModel.garageVehicles
//    }
//
//    var body: some View {
//        Text("gell")
//    }
//
//    // MARK: Bluetooth Section
//
//    // Bluetooth Section
//
//    private var bluetoothSection: some View {
//        VStack {
//            GroupBox(label: SettingsLabelView(labelText: "Adapter", labelImage: "wifi.circle")) {
//                Divider().padding(.vertical, 4)
//
//                VStack {
//                    Text("Device: \(viewModel.elmAdapter?.name ?? "")")
//                        .font(.headline)
//                        .frame(maxWidth: .infinity, alignment: .leading)
//                    Spacer()
//                }
//            }
//            .padding()
//        }
//        .padding()
//    }
//
//    // MARK: Garage Section
//
//    private var garageSection: some View {
//        VStack {
//            carDetailsView()
//            if isExpandedCarInfo {
//                Divider().padding(.vertical, 4)
//                carInfoExpandedView()
//            }
//            if isExpandedOtherCars {
//                Divider().padding(.vertical, 4)
//                otherVehiclesView()
//            }
//            Spacer()
//            Button(action: {
//                withAnimation(.easeInOut(duration: 0.3)) {
//                    isExpandedOtherCars.toggle()
//                }
//            }, label: {
//                Image(systemName: "chevron.down.circle")
//                    .font(.title)
//                    .rotationEffect(.degrees(isExpandedOtherCars ? 180 : 0))
//                    .foregroundColor(.gray)
//
//            })
//            .padding()
//        }
//    }
//
//    private func carDetailsView() -> some View {
//        VStack(spacing: 20) {
//            HStack {
//                if let car = selectedCar {
//                    Text(car.make)
//                    Spacer()
//                    Text(car.model)
//                    Spacer()
//                    Text(car.year)
//                    Spacer()
//
//                    Image(systemName: isExpandedCarInfo ? "chevron.up" : "chevron.down")
//                        .resizable()
//                        .frame(width: 17, height: 10)
//                        .foregroundColor(.gray)
//                        .onTapGesture {
//                            withAnimation(.spring()) {
//                                isExpandedCarInfo.toggle()
//                            }
//                        }
//                }
//            }
//            .frame(maxWidth: .infinity, alignment: .leading)
//            Divider().padding(.vertical, 4)
//        }
//        .modifier(RoundedRectangleStyle())
//    }
//
//    private func carInfoExpandedView() -> some View {
//        VStack {
//            // Supported PIDs
//            Text("Supported PIDs")
//                .font(.headline)
//                .padding()
//                .frame(maxWidth: .infinity, alignment: .leading)
//
//            if let supportedPIDs = viewModel.garageVehicles[selectedCarIndex].obdinfo?.supportedPIDs {
//                List(supportedPIDs, id: \.self) { pid in
//                    HStack {
//
//                        Text(pid.description)
//                            .font(.caption)
//                            .padding()
//
//                        if let pidData = viewModel.pidData[pid] {
//                            Text("\(pidData.value) \(pidData.unit)")
//                                .font(.caption)
//                                .padding()
//
//                        }
//                    }
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                    .background(
//                        RoundedRectangle(cornerRadius: 10)
//                            .fill(LinearGradient(Color.darkStart, Color.darkEnd))
//                            .shadow(color: Color.darkEnd, radius: 5, x: -3, y: -3)
//                            .shadow(color: Color.darkStart, radius: 5, x: 3, y: 3))
//                    .onTapGesture {
////                        viewModel.startRequestingPID(pid: pid)
//                    }
//                }
//                .frame(minHeight: 300)
//                .listStyle(PlainListStyle())
//            }
//        }
//        .offset(y: isExpandedCarInfo ? 0 : -100) // Slide down the content
//        .opacity(isExpandedCarInfo ? 1 : 0) // Fade in the content
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//    }
//
//    private func otherVehiclesView() -> some View {
//        VStack {
//            ForEach(garageVehicles) { car in
//                HStack {
//                    Text(car.make)
//                    Spacer()
//                    Text(car.model)
//                    Spacer()
//                    Text(car.year)
//                    Spacer()
//                    Button {
//                        viewModel.deleteVehicle(car)
//                    } label: {
//                        Image(systemName: "trash")
//                            .foregroundColor(.red)
//                    }
//                }
//                .frame(maxWidth: .infinity)
//                .padding()
//                .onTapGesture {
//                    if selectedCarIndex != garageVehicles.firstIndex(where: { $0.id == car.id }) {
//                        withAnimation {
//                            selectedCarIndex = garageVehicles.firstIndex(where: { $0.id == car.id })!
//                        }
//                    }
//                }
//            }
//            if addVehicle {
//                VehiclePickerView(viewModel: viewModel)
//            }
//            Button {
//                addVehicle.toggle()
//            } label: {
//                Text("Add Vehicle")
//            }
//            .buttonStyle(ShadowButtonStyle())
//        }
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//        .offset(y: isExpandedOtherCars ? 0 : -100) // Slide down the content
//        .opacity(isExpandedOtherCars ? 1 : 0) // Fade in the content
//    }
//
//    // MARK: ELM Section
//
//    private var elmSection: some View {
//        GroupBox(label: SettingsLabelView(labelText: "ELM", labelImage: "info.circle")) {
//            Divider().padding(.vertical, 4)
//            ProtocolPicker(selectedProtocol: $viewModel.selectedProtocol)
//            HStack {
//                Button("Setup Order") {
//                    isSetupOrderPresented.toggle()
//                }
//                .buttonStyle(ShadowButtonStyle())
//                .sheet(isPresented: $isSetupOrderPresented) {
//                    SetupOrderModal(isModalPresented: $isSetupOrderPresented, setupOrder: $setupOrder)
//                }
//            }
//        }
//    }
//}
//


//struct SettingsScreen_Previews: PreviewProvider {
//    static var previews: some View {
//        let previewViewModel = SettingsScreenViewModel(elm327: ELM327(bleManager: BLEManager()))
//        return SettingsScreen(viewModel: previewViewModel)
//    }
//}
