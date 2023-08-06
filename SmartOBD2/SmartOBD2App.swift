//
//  SmartOBD2App.swift
//  SmartOBD2
//
//  Created by kemo konteh on 8/3/23.
//

import SwiftUI

@main
struct SmartOBD2App: App {
    @StateObject private var elmComm = ELMComm()
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(elmComm)
        }
    }
}
