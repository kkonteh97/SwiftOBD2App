//
//  CarScreenViewModel.swift
//  SmartOBD2
//
//  Created by kemo konteh on 9/1/23.
//

import Foundation

class CarScreenViewModel: ObservableObject {

    let obdService: OBDService

    @Published var command: String = ""

    init(obdService: OBDService) {
        self.obdService = obdService
    }

    func sendMessage() async throws -> [String] {
        return try await obdService.elm327.sendMessageAsync(command, withTimeoutSecs: 5)
    }
}
