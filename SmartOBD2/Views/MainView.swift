//
//  TabView.swift
//  SmartOBD2
//
//  Created by kemo konteh on 8/5/23.
//

import SwiftUI
import CoreBluetooth

struct CarlyObd {
    static let elmServiceUUID = "FFE0"
    static let elmCharactericUUID = "FFE1"
}

struct MainView: View {
    @Environment(\.colorScheme) var colorScheme
    @State var displayType: BottomSheetType = .quarterScreen

    let obdService = OBDService(bleManager: BLEManager())

    let homeViewModel: HomeViewModel
    let liveDataViewModel: LiveDataViewModel
    let bottomSheetViewModel: BottomSheetViewModel
    let garageViewModel: GarageViewModel

    @AppStorage("selectedCarId") var selectedCarId: Int = 1

    init(garage: Garage) {
        self.homeViewModel = HomeViewModel(obdService: obdService, garage: garage)
        self.liveDataViewModel = LiveDataViewModel(obdService: obdService)
        self.bottomSheetViewModel = BottomSheetViewModel(obdService: obdService, garage: garage)
        self.garageViewModel = GarageViewModel(garage: garage)
    }

    var body: some View {
            GeometryReader { proxy in
                BottomSheet(viewModel: bottomSheetViewModel,
                            displayType: $displayType,
                            selectedCar: $selectedCarId,
                            maxHeight: proxy.size.height
                ) {
                    NavigationView {
                    HomeView(
                             viewModel: homeViewModel,
                             liveDataViewModel: liveDataViewModel,
                             garageViewModel: garageViewModel,
                             displayType: $displayType,
                             selectedVehicle: $selectedCarId
                        )
                        .navigationBarTitle("SMARTOBD2")
                        .navigationBarTitleDisplayMode(.large)
                        .background(LinearGradient(.darkStart, .darkEnd))
                    }
            }
        }
    }
}

#Preview {
    MainView(garage: Garage())
}
