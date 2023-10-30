//
//  UnitTestingBootcampViewModel.swift
//  SMARTOBD2
//
//  Created by kemo konteh on 10/18/23.
//

import Foundation
class UnitTestingBootcampViewModel: ObservableObject {
    @Published var isPremium: Bool
    @Published var dataArray: [String] = []
    @Published var selectedItem: String? = nil


    init(isPremium: Bool) {
        self.isPremium = isPremium
    }

    func addItem(item: String) {
        guard !item.isEmpty else { return }
        self.dataArray.append(item)
    }

    func selectItem(item: String) {
        if let x = dataArray.first(where: { $0 == item}) {
            selectedItem = x
        }
    }
}
