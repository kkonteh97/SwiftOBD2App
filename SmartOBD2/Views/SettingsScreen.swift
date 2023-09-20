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

enum Constants {
    static let radius: CGFloat = 16
    static let indicatorWidth: CGFloat = 40
    static let indicatorHeight: CGFloat = 6
    static let minHeightRatio: CGFloat = 0.2
    static let snapRatio: CGFloat = 0.25
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
    @State private var addVehicle = false

    @AppStorage("selectedCarIndex") var selectedCarIndex = 0
    @State private var bottomSheetShown = false
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
        Text("gell")
    }

// MARK: Bluetooth Section

    // Bluetooth Section

    private var bluetoothSection: some View {
        VStack {
            GroupBox(label: SettingsLabelView(labelText: "Adapter", labelImage: "wifi.circle")) {
                Divider().padding(.vertical, 4)

                VStack {

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

    // MARK: ELM Section

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

struct ConnectButton<Content: View>: View {
    @Binding var isLoading: Bool
    let label: Content


    init(isLoading: Binding<Bool>, @ViewBuilder label: () -> Content) {
        self._isLoading = isLoading
        self.label = label()
    }

    var body: some View {
        Button {
            let impactLight = UIImpactFeedbackGenerator(style: .medium)
            impactLight.impactOccurred()
            self.isLoading = true
//                    try await viewModel.setupAdapter(setupOrder: setupOrder)
                    // remove when done
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.isLoading = false
                    }

        } label: {
            VStack {
                if isLoading {
                    ProgressView()
                } else {
                    self.label


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
}
struct BottomSheetView<Content: View>: View {
    @Binding var isOpen: Bool
    
    let maxHeight: CGFloat
    let minHeight: CGFloat
    let content: Content

    init(isOpen: Binding<Bool>, maxHeight: CGFloat, @ViewBuilder content: () -> Content) {
        self.minHeight = maxHeight * Constants.minHeightRatio
        self.maxHeight = maxHeight
        self.content = content()
        self._isOpen = isOpen
    }

    private var offset: CGFloat {
        isOpen ? 0 : maxHeight - minHeight
    }

    private var indicator: some View {
        HStack {
            Text("Not Connect")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            ConnectButton(isLoading: .constant(false)) {
                Text("Initialize Vehicle")
                    .font(.headline)
            }

        }


//        RoundedRectangle(cornerRadius: Constants.radius)
//            .fill(Color.secondary)
//            .frame(
//                width: Constants.indicatorWidth,
//                height: Constants.indicatorHeight
//        )
    }

    @GestureState private var translation: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                self.indicator.padding()
                Divider().padding(.vertical, 4)
                self.content
            }
            .frame(width: geometry.size.width, height: self.maxHeight, alignment: .top)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(Constants.radius)
            .frame(height: geometry.size.height, alignment: .bottom)
            .offset(y: max(self.offset + self.translation, 0))
            .animation(.interactiveSpring(), value: isOpen)
            .animation(.interactiveSpring(), value: translation)
            .gesture(
                DragGesture().updating(self.$translation) { value, state, _ in
                    state = value.translation.height
                }.onEnded { value in
                    let snapDistance = self.maxHeight * Constants.snapRatio
                    guard abs(value.translation.height) > snapDistance else {
                        return
                    }
                    self.isOpen = value.translation.height < 0
                }
            )
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
