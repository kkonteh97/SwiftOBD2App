//
//  SettingsScreenViewModel.swift
//  SmartOBD2
//
//  Created by kemo konteh on 8/31/23.
//

import Foundation

class SettingsScreenViewModel: ObservableObject {
    let elmManager: ElmManager
    
    init(elmManager: ElmManager) {
        self.elmManager = elmManager
    }
    
    func setupAdapter(setupOrder: [SetupStep]) async throws -> OBDInfo {
            return try await elmManager.setupAdapter(setupOrder: setupOrder)
    }
    
    func sendMessage(_ message: String) async throws -> String  {
        return try await elmManager.sendMessageAsync(message, withTimeoutSecs: 5)
    }
}
