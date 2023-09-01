//
//  CarScreenViewModel.swift
//  SmartOBD2
//
//  Created by kemo konteh on 9/1/23.
//

import Foundation

class CarScreenViewModel: ObservableObject {
    let elmManager: ElmManager
    
    init(elmManager: ElmManager) {
        self.elmManager = elmManager
    }
    
    func sendMessage(_ message: String) async throws -> String  {
        return try await elmManager.sendMessageAsync(message, withTimeoutSecs: 5)
    }
}
