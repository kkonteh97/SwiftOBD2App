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
    @State private var tabSelection: TabBarItem = .dashBoard

    let homeViewModel: HomeViewModel
    let liveDataViewModel: LiveDataViewModel
    let bottomSheetViewModel: BottomSheetViewModel
    let garageViewModel: GarageViewModel
    let carScreenViewModel: CarScreenViewModel

    init(garage: Garage, obdService: OBDService) {
        self.homeViewModel = HomeViewModel(obdService: obdService, garage: garage)
        self.liveDataViewModel = LiveDataViewModel(obdService: obdService, garage: garage)
        self.bottomSheetViewModel = BottomSheetViewModel(obdService: obdService, garage: garage)
        self.carScreenViewModel = CarScreenViewModel(obdService: obdService)
        self.garageViewModel = GarageViewModel(garage: garage)
    }

    var body: some View {
            GeometryReader { proxy in
                CustomTabBarContainerView(selection: $tabSelection,
                                          displayType: $displayType,
                                          maxHeight: proxy.size.height,
                                          viewModel: bottomSheetViewModel
                ) {
                    NavigationView {
                        HomeView(viewModel: homeViewModel,
                                 garageViewModel: garageViewModel,
                                 displayType: $displayType)
                        .background(LinearGradient(.darkStart, .darkEnd))
                    }
                    .navigationViewStyle(StackNavigationViewStyle())
                    .tabBarItem(tab: .dashBoard, selection: $tabSelection)

                    NavigationView {
                        DashBoardView(
                            liveDataViewModel: liveDataViewModel,
                            displayType: $displayType
                        )
                        .background(LinearGradient(.slategray, .raisinblack))
                    }
                    .navigationViewStyle(StackNavigationViewStyle())
                    .tabBarItem(tab: .features, selection: $tabSelection)
//                    NavigationView {
//                        CarScreen(
//                            viewModel: carScreenViewModel
//                        )
//                        .background(LinearGradient(.slategray, .raisinblack))
//                    }
//                    .navigationViewStyle(StackNavigationViewStyle())
//                    .tabBarItem(tab: .features, selection: $tabSelection)
            }
        }
    }
}

#Preview {
    MainView(garage: Garage(),
             obdService: OBDService(bleManager: BLEManager()))
}
