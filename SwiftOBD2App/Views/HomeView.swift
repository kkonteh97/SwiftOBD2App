//
//  HomeView.swift
//  SMARTOBD2
//
//  Created by kemo konteh on 9/30/23.
//

import SwiftUI
import SwiftOBD2

struct HomeView: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var displayType: BottomSheetType
    @Binding var isDemoMode: Bool
    @Binding var statusMessage: String?

    var body: some View {
        ZStack {
            BackgroundView(isDemoMode: $isDemoMode)
            ScrollView(.vertical, showsIndicators: false) {
                VStack {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                        SectionView(title: "Diagnostics",
                                    subtitle: "Read Vehicle Health",
                                    iconName: "wrench.and.screwdriver",
                                    destination: VehicleDiagnosticsView(displayType: $displayType, isDemoMode: $isDemoMode)
                        )

                        SectionView(title: "Logs",
                                    subtitle: "View Logs",
                                    iconName: "flowchart",
                                    destination: LogsView())
                        .simultaneousGesture(TapGesture().onEnded {
                            withAnimation {
                                displayType = .none
                            }
                        })
                        .disabled(true)
                        .opacity(0.5)
                        .overlay(Text("Coming Soon")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(5)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(5)
                            .padding(5), alignment: .topTrailing)
                    }
                    .padding(20)
                    .padding(.bottom, 20)

                    Divider().background(Color.white).padding(.horizontal, 10)
                    NavigationLink(destination: GarageView(displayType: $displayType,
                                                           isDemoMode: $isDemoMode)) {
                        SettingsAboutSectionView(title: "Garage", iconName: "car.circle", iconColor: .blue.opacity(0.6))
                    }
                                                           .simultaneousGesture(TapGesture().onEnded {
                                                               withAnimation {
                                                                   displayType = .none
                                                               }
                                                           })

                    NavigationLink {
                        SettingsView(displayType: $displayType, 
                                     isDemoMode: $isDemoMode)
                    } label: {
                        SettingsAboutSectionView(title: "Settings", iconName: "gear", iconColor: .green.opacity(0.6))
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        withAnimation {
                            displayType = .none
                        }
                    })

                    NavigationLink {
                        TestingScreen(displayType: $displayType)
                    } label: {
                        SettingsAboutSectionView(title: "Testing Hub", iconName: "gear", iconColor: .green.opacity(0.6))
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        withAnimation {
                            displayType = .none
                        }
                    })
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                HStack {
                    Text("Powered by SMARTOBD2")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(5)
                }
            }
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

#Preview {
    NavigationView {
        HomeView(displayType: .constant(.quarterScreen), isDemoMode: .constant(true), statusMessage: .constant(nil))
    }.navigationViewStyle(.stack)
}
