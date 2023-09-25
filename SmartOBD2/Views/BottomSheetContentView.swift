//
//  BottomSheetContentView.swift
//  SMARTOBD2
//
//  Created by kemo konteh on 9/21/23.
//

import SwiftUI



struct BottomSheetContent: View {
    @Binding var displayType: BottomSheetType
    @ObservedObject var viewModel: HomeViewModel

    @State private var isExpandedCarInfo = false
    @State private var isExpandedOtherCars = false

    @State private var addVehicle = false

    var maxHeight: CGFloat // Height of the content section

    @AppStorage("selectedCarIndex") var selectedCarIndex = 0

    var selectedCar: GarageVehicle? {
        guard selectedCarIndex < viewModel.garageVehicles.count,
                !viewModel.garageVehicles.isEmpty else {
            selectedCarIndex = 0
            return nil
        }
        return viewModel.garageVehicles[selectedCarIndex]
    }

    var garageVehicles: [GarageVehicle] {
        viewModel.garageVehicles
    }

    func displayToggle() {
        switch displayType {
        case .none:
            displayType = .halfScreen
        case .halfScreen:
            displayType = .fullScreen
        case .fullScreen:
            displayType = .none
        }
    }

    private var indicator: some View {
        VStack {
            RoundedRectangle(cornerRadius: Constants.radius)
                .fill(Color.secondary)
                .frame(
                    width: Constants.indicatorWidth,
                    height: Constants.indicatorHeight
                )
        }.onTapGesture {
                withAnimation(.interactiveSpring(response: 0.5, dampingFraction: 0.8, blendDuration: 0)) {
                    displayToggle()
                }
            }
        }


    var body: some View {
        VStack(spacing: 0) {
            VStack {
                self.indicator
                    .padding(10)

                carDetailsView()
                    .padding(.bottom)
                    .scaleEffect(displayType == .none ? 0.90 : 1)
                    }
                    .frame(maxWidth: .infinity,maxHeight: (maxHeight * 0.1))
                    .padding()

            carInfoView
                .frame(maxHeight:  maxHeight * 0.4 - maxHeight * 0.1)
//                .border(Color.red)

            garageSection
                .frame(maxWidth: .infinity, maxHeight: .infinity)
//                .border(Color.red)
        }
    }

    private func carDetailsView() -> some View {
        HStack(spacing: 60) {
            if let car = selectedCar {
                Text(car.year)
                Text(car.make)
                Text(car.model)
            }
        }
        .modifier(RoundedRectangleStyle())
    }

    private var garageSection: some View {
        VStack {
            otherVehiclesView()
            Spacer()
        }
        .padding()
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
    }

    private var carInfoView: some View {
        HStack(spacing: 20) {
                if let car = selectedCar {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Protocol \n" + (car.obdinfo?.obdProtocol.description ?? "Unknown"))
                            .font(.caption)

                        Text("VIN \n" + car.vin)
                            .font(.caption)

                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    ScrollView(.vertical, showsIndicators: false) {
                        if let supportedPIDs = car.obdinfo?.supportedPIDs {
                            ForEach(supportedPIDs, id: \.self) { pid in
                                HStack {
                                    Text(pid.description)
                                        .font(.caption)

                                    if let pidData = viewModel.pidData[pid] {
                                        Text("\(pidData.value) \(pidData.unit)")
                                            .font(.caption)
                                    }
                                }
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(LinearGradient(Color.darkStart, Color.darkEnd))
                                    )
                                .onTapGesture {
                                    viewModel.startRequestingPID(pid: pid)
                                }
                            }
                        }
                }
            }

        }
        .padding(10)
        .frame(maxWidth: .infinity)
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

#Preview {
    ZStack {
        GeometryReader { proxy in
            BottomSheetContent(displayType: .constant(.none), viewModel: HomeViewModel(elm327: ELM327(bleManager: BLEManager())), maxHeight: proxy.size.height)
        }
    }
}
