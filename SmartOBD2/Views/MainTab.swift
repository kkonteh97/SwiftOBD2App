//
//  TabView.swift
//  SmartOBD2
//
//  Created by kemo konteh on 8/5/23.
//

import SwiftUI



extension String {
    subscript(offset: Int) -> Character {
        self[index(startIndex, offsetBy: offset)]
    }
}



struct MainTab: View {
    @EnvironmentObject var elmComm: ELMComm
        
    @State private var tabSelected: TabBarItem = .favourites
    @ObservedObject private var bluetoothViewModel = BluetoothViewModel()
    
    var body: some View {
        CustomTabBarContainerView(selection: $tabSelected) {
            HomeScreen()
                .tabBarItem(tab: .home, selection: $tabSelected)
                .environmentObject(bluetoothViewModel) // Pass the bluetoothViewModel here

            
            CarScreen()
                .tabBarItem(tab: .favourites, selection: $tabSelected)
                .environmentObject(bluetoothViewModel) // Pass the bluetoothViewModel here

            SettingsScreen()
                .tabBarItem(tab: .profile, selection: $tabSelected)
                .environmentObject(bluetoothViewModel) // Pass the bluetoothViewModel here

        }
    }
}

struct VINResults: Codable {
    let Results: [VINInfo]
}

struct VINInfo: Codable, Hashable {
    let Make: String
    let Model: String
    let ModelYear: String
    let EngineCylinders: String
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainTab()
    }
}
