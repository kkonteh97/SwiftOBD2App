//
//  TabView.swift
//  SmartOBD2
//
//  Created by kemo konteh on 8/5/23.
//

import SwiftUI
import CoreBluetooth

struct MainView: View {
    @Environment(\.colorScheme) var colorScheme
    @State var SplashScreenIsActive: Bool = true
    @State private var tabSelection: TabBarItem = .dashBoard

    let homeViewModel: HomeViewModel
    let garageViewModel: GarageViewModel
    let liveDataViewModel: LiveDataViewModel
    let settingsViewModel: SettingsViewModel
    let bottomSheetViewModel: CustomTabBarViewModel
    let testingScreenViewModel: TestingScreenViewModel
    let diagnosticsViewModel: VehicleDiagnosticsViewModel

    init(garage: Garage) {
        let obdService = OBDService()
        self.garageViewModel        =   GarageViewModel(obdService, garage)
        self.settingsViewModel      =   SettingsViewModel(obdService,  garage)
        self.homeViewModel          =   HomeViewModel(obdService, garage)
        self.liveDataViewModel      =   LiveDataViewModel(obdService, garage)
        self.bottomSheetViewModel   =   CustomTabBarViewModel(obdService, garage)
        self.testingScreenViewModel =   TestingScreenViewModel(obdService, garage)
        self.diagnosticsViewModel   =   VehicleDiagnosticsViewModel(obdService, garage)
    }

    var body: some View {
        GeometryReader { proxy in
            if SplashScreenIsActive {
                SplashScreenView(isActive: $SplashScreenIsActive)
            } else {
                CustomTabBarContainerView(
                      selection: $tabSelection,
                      maxHeight: proxy.size.height,
                      viewModel: bottomSheetViewModel
                ) {
                    NavigationView {
                        HomeView(
                             viewModel: homeViewModel,
                             diagnosticsViewModel: diagnosticsViewModel,
                             garageViewModel: garageViewModel,
                             settingsViewModel: settingsViewModel,
                             testingScreenViewModel: testingScreenViewModel
                        )
                        .background(LinearGradient(.darkStart, .darkEnd))
                    }
                    .navigationViewStyle(StackNavigationViewStyle())
                    .tabBarItem(tab: .dashBoard, selection: $tabSelection)

                    NavigationView {
                        DashBoardView(
                            liveDataViewModel: liveDataViewModel
                        )
                        .background(LinearGradient(.slategray, .raisinblack))
                    }
                    .navigationViewStyle(StackNavigationViewStyle())
                    .tabBarItem(tab: .features, selection: $tabSelection)
                }
            }
        }
    }
}

#Preview {
    MainView(garage: Garage())
        .environmentObject(GlobalSettings())
}

