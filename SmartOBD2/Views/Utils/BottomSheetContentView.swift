//
//  BottomSheetContentView.swift
//  SMARTOBD2
//
//  Created by kemo konteh on 9/21/23.
//

import SwiftUI

struct BottomSheetContent: View {
    @Binding var displayType: BottomSheetType
    @Binding var selectedVehicle: Int

    @ObservedObject var viewModel: BottomSheetViewModel

    @State private var isExpandedCarInfo = false
    @State private var isExpandedOtherCars = false

    @Environment(\.colorScheme) var colorScheme

    @State private var addVehicle = false

    var maxHeight: CGFloat // Height of the content section

    var garageVehicles: [GarageVehicle] {
        viewModel.garageVehicles
    }

    func displayToggle() {
        switch displayType {
        case .quarterScreen:
            displayType = .halfScreen
        case .halfScreen:
            displayType = .fullScreen
        case .fullScreen:
            displayType = .quarterScreen
        case .none:
            displayType = .quarterScreen
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

                HStack(spacing: 60) {
                    if let car = garageVehicles.first(where: { $0.id == selectedVehicle }) {

                        Text(car.year)
                        Text(car.make)
                        Text(car.model)
                    }
                }
                .modifier(RoundedRectangleStyle())
                .foregroundColor(Color.primary)
                .font(.system(size: 20, weight: .bold))
                .padding(.bottom)
                .scaleEffect(displayType == .none ? 0.90 : 1)
            }
            .frame(maxWidth: .infinity, maxHeight: (maxHeight * 0.1))
            .padding()

            carInfoView
                .frame(maxHeight: maxHeight * 0.4 - maxHeight * 0.1)

            garageSection
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var garageSection: some View {
        VStack {
            otherVehiclesView()
            Spacer()
        }
        .padding()
    }

    private func otherVehiclesView() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Garage")
                    .font(.title)
                    .fontWeight(.bold)
                Spacer()
                Button {
                    withAnimation {
                        addVehicle.toggle()
                    }
                } label: {
                    Text("Add Vehicle")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.blue)
                        .padding(10)
                        .background {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.blue, lineWidth: 2)
                        }
                }
            }
            .padding(.bottom)

            ForEach(garageVehicles) { vehicle in
                HStack(spacing: 10) {
                    Text(vehicle.make)
                    Spacer()
                    Text(vehicle.model)
                    Spacer()
                    Text(vehicle.year)
                    Spacer()
                    Button {
                        viewModel.deleteVehicle(vehicle)
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
                .frame(maxWidth: .infinity)
                .modifier(RoundedRectangleStyle())
                .onTapGesture {
                    withAnimation {
                        selectedVehicle =  vehicle.id
                    }
                }
            }
            }
        .padding()
    }

    private var carInfoView: some View {
        HStack(spacing: 20) {
            if let car = garageVehicles.first(where: { $0.id == selectedVehicle }) {
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

//                                if let pidData = viewModel.pidData[pid] {
//                                    Text("\(pidData.value) \(pidData.unit)")
//                                        .font(.caption)
//                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .modifier(RoundedRectangleStyle())
                            .onTapGesture {
//                                viewModel.startRequestingPID(pid: pid)
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

#Preview {
    ZStack {
        GeometryReader { proxy in
            BottomSheetContent(displayType: .constant(.quarterScreen), selectedVehicle: .constant(0),
                               viewModel: BottomSheetViewModel(obdService: OBDService(bleManager: BLEManager()), garage: Garage()),
                               maxHeight: proxy.size.height
            )
        }
    }
}

// struct ShadowButtonStyle: ButtonStyle {
//    @Environment(\.colorScheme) var colorScheme
//
//    func makeBody(configuration: Configuration) -> some View {
//        configuration.label
//            .font(.headline)
//            .frame(width: 170, height: 50)
//            .background(
//                RoundedRectangle(cornerRadius: 25)
//                    .fill(LinearGradient(.startColor(), .endColor()))
//                    .shadow(color: .endColor(), radius: 5, x: -3, y: -3)
//                    .shadow(color: .startColor(), radius: 5, x: 3, y: 3)
//            )
//    }
// }
