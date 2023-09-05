//
//  CarScreenViewModel.swift
//  SmartOBD2
//
//  Created by kemo konteh on 9/1/23.
//

import Foundation

class CarScreenViewModel: ObservableObject {
    @Published var command: String = ""

    let elmManager: ElmManager
    
    init(elmManager: ElmManager) {
        self.elmManager = elmManager
    }
    
    func sendMessage() async throws -> String  {
        return try await elmManager.sendMessageAsync(command, withTimeoutSecs: 5)
    }
}
