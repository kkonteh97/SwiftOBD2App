//
//  HomeView.swift
//  SMARTOBD2
//
//  Created by kemo konteh on 9/30/23.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @ObservedObject var liveDataViewModel: LiveDataViewModel
    @ObservedObject var garageViewModel: GarageViewModel

    @Binding var displayType: BottomSheetType
    @Binding var selectedVehicle: Int

    @Environment(\.colorScheme) var colorScheme

    var garageVehicles: [GarageVehicle] {
        viewModel.garageVehicles
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack {
                HStack(spacing: 10) {
                    VStack {
                        NavigationLink {
                            VehicleDiagnosticsView(viewModel: viewModel)
                        } label: {
                            SectionView(title: "Diagnostics", subtitle: "Read Vehicle Health", iconName: "wrench.and.screwdriver")
                        }

                        NavigationLink {
                            VehicleDiagnosticsView(viewModel: viewModel)
                        } label: {
                            SectionView(title: "Logs", subtitle: "View Logs", iconName: "flowchart")
                        }
                    }
                    VStack {
                        NavigationLink {
                            BatteryTestView()
                        } label: {
                            SectionView(title: "Battery", subtitle: "Monitor Battery Health", iconName: "minus.plus.batteryblock")
                        }

                        NavigationLink {
                            LiveDataView(viewModel: liveDataViewModel)
                        } label: {
                            SectionView(title: "Live Data", subtitle: "Vehicle Live Data", iconName: "chart.xyaxis.line")
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.top, 10)
                Spacer()

                VStack {
                    Divider().background(Color.white).padding(.horizontal, 20)
                    NavigationLink {
                        GarageView(viewModel: garageViewModel, selectedVehicle: $selectedVehicle)
                    } label: {
                        SettingsAboutSectionView(title: "Garage", iconName: "car.circle", iconColor: .blue.opacity(0.6))
                    }
                    Divider().background(Color.white).padding(.horizontal, 20)
                    NavigationLink {
                        SettingsView()
                    } label: {
                        SettingsAboutSectionView(title: "Settings", iconName: "gear", iconColor: .green.opacity(0.6))
                    }

                    Divider().background(Color.white).padding(.horizontal, 20)
                    NavigationLink {
                        AboutView()
                            .onAppear {
                                withAnimation {
                                    self.displayType = .none
                                }
                            }
                            .onDisappear {
                                withAnimation {
                                    self.displayType = .quarterScreen
                                }
                            }
                            .transition(.move(edge: .bottom))

                    } label: {
                        SettingsAboutSectionView(title: "About", iconName: "info.circle", iconColor: .secondary)
                    }
                    Divider().background(Color.white).padding(.horizontal, 20)

                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .padding(.top, 20)
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

struct SectionView: View {
    let title: String
    let subtitle: String
    let iconName: String

    init(title: String, subtitle: String, iconName: String) {
        self.title = title
        self.subtitle = subtitle
        self.iconName = iconName
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
                Image(systemName: iconName)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)

            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)

            HStack {
                Text(subtitle)
                    .lineLimit(2)
                    .font(.system(size: 12, weight: .semibold))
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.gray)

                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal)
        .frame(width: 160, height: 160)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.cyclamen)
        }
    }
}

struct SettingsView: View {
    var body: some View {
        Text("Settings")
    }
}

#Preview {
    ZStack {
        LinearGradient(.darkStart, .darkEnd)
            .ignoresSafeArea()
        HomeView(
                 viewModel: HomeViewModel(obdService: OBDService(bleManager: BLEManager()),
                 garage: Garage()),
                 liveDataViewModel: LiveDataViewModel(obdService: OBDService(bleManager: BLEManager())),
                 garageViewModel: GarageViewModel(garage: Garage()), displayType: .constant(.quarterScreen),
                 selectedVehicle: .constant(1))
    }
}
