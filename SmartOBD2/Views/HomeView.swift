//
//  HomeView.swift
//  SMARTOBD2
//
//  Created by kemo konteh on 9/30/23.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @ObservedObject var diagnosticsViewModel: VehicleDiagnosticsViewModel
    @ObservedObject var garageViewModel: GarageViewModel
    @ObservedObject var settingsViewModel: SettingsViewModel
    @ObservedObject var testingScreenViewModel: TestingScreenViewModel

    @EnvironmentObject var globalSettings: GlobalSettings
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 0), GridItem(.flexible(), spacing: 0)], spacing: 20) {
                    SectionView(title: "Diagnostics", 
                                subtitle: "Read Vehicle Health",
                                iconName: "wrench.and.screwdriver",
                                destination: VehicleDiagnosticsView(viewModel: diagnosticsViewModel))
                    SectionView(title: "Logs",
                                subtitle: "View Logs",
                                iconName: "flowchart",
                                destination: LogsView())
                    SectionView(title: "Battery",
                                subtitle: "Monitor Battery Health",
                                iconName: "minus.plus.batteryblock",
                                destination: BatteryTestView())
                }
                .padding(.vertical, 20)

                Divider().background(Color.white).padding(.horizontal, 20)
                NavigationLink {
                    SettingsView(viewModel: settingsViewModel)
                        .background(LinearGradient(.darkStart, .darkEnd))
                } label: {
                    SettingsAboutSectionView(title: "Settings", iconName: "gear", iconColor: .green.opacity(0.6))
                }

                Divider().background(Color.white).padding(.horizontal, 20)
                
                NavigationLink(destination: GarageView(viewModel: garageViewModel)) {
                    SettingsAboutSectionView(title: "Garage", iconName: "car.circle", iconColor: .blue.opacity(0.6))
                }.simultaneousGesture(TapGesture().onEnded{
                    globalSettings.displayType = .none
                })
                Divider().background(Color.white).padding(.horizontal, 20)
                NavigationLink(destination: AboutView()) {
                    SettingsAboutSectionView(title: "About", iconName: "info.circle", iconColor: .secondary)
                }.simultaneousGesture(TapGesture().onEnded{
                    globalSettings.displayType = .none
                })

                Divider().background(Color.white).padding(.horizontal, 20)
                NavigationLink {
                    TestingScreen(viewModel: testingScreenViewModel)
                        .background(LinearGradient(.darkStart, .darkEnd))
                        .onAppear {
                            withAnimation {
                                globalSettings.displayType = .none
                            }
                        }
                        .onDisappear {
                            withAnimation {
                                globalSettings.displayType = .quarterScreen
                            }
                        }
                        .transition(.move(edge: .bottom))

                } label: {
                    SettingsAboutSectionView(title: "Testing Hub", iconName: "car.circle", iconColor: .blue.opacity(0.6))
                }

                Divider().background(Color.white).padding(.horizontal, 20)
            }
            .padding()
        }
    }
}

struct SettingsAboutSectionView: View {
    let title: String
    let iconName: String
    let iconColor: Color

    var body: some View {
        HStack {
            Image(systemName: iconName)
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(iconColor)

            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)

        }
        .frame(maxWidth: .infinity, maxHeight: 400, alignment: .leading)
        .padding(.horizontal, 22)
    }
}

//#Preview {
//    ZStack {
//        LinearGradient(.darkStart, .darkEnd)
//            .ignoresSafeArea()
//        HomeView(
//            viewModel: HomeViewModel(obdService: OBDService(),
//                                     garage: Garage()),
//            diagnosticsViewModel: VehicleDiagnosticsViewModel(obdService: OBDService(),
//                           garage: Garage()),
//            garageViewModel: GarageViewModel(obdService: OBDService(), garage: Garage()),
//            settingsViewModel: SettingsViewModel(obdService: OBDService()),
//            testingScreenViewModel: TestingScreenViewModel(obdService: OBDService(), garage: Garage()))
//    }
//}
