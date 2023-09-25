//
//  CarScreenViewModel.swift
//  SmartOBD2
//
//  Created by kemo konteh on 9/1/23.
//

import Foundation

class CarScreenViewModel: ObservableObject {

    let elm327: ELM327

    @Published var command: String = ""

    init(elm327: ELM327) {
        self.elm327 = elm327
    }

    func sendMessage() async throws -> [String] {
        return try await elm327.sendMessageAsync(command, withTimeoutSecs: 5)
    }
}
