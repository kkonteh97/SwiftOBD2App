//
//  TabView.swift
//  SmartOBD2
//
//  Created by kemo konteh on 8/5/23.
//

import SwiftUI
import SwiftOBD2

struct MainView: View {
    @State private var tabSelection: TabBarItem = .dashBoard
    @State var displayType: BottomSheetType = .quarterScreen
    @State var statusMessage: String?
    @State var isDemoMode = false

    var body: some View {
        GeometryReader { proxy in
            CustomTabBarContainerView(
                  selection: $tabSelection,
                  maxHeight: proxy.size.height,
                  displayType: $displayType,
                  statusMessage: $statusMessage
            ) {
                NavigationView {
                    HomeView(displayType: $displayType, isDemoMode: $isDemoMode, statusMessage: $statusMessage)
                }
                .navigationViewStyle(.stack)
                .tabBarItem(tab: .dashBoard, selection: $tabSelection)

                NavigationView {
                    LiveDataView(displayType: $displayType,
                        statusMessage: $statusMessage,
                        isDemoMode: $isDemoMode
                    )
                }
                .navigationViewStyle(.stack)
                .tabBarItem(tab: .features, selection: $tabSelection)
            }
        }
    }
}

#Preview {
    MainView()
        .environmentObject(GlobalSettings())
        .environmentObject(Garage())
        .environmentObject(OBDService())
}


