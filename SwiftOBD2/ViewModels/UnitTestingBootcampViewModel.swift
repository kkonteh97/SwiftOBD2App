//
//  UnitTestingBootcampViewModel.swift
//  SMARTOBD2
//
//  Created by kemo konteh on 10/18/23.
//

import Foundation
import Combine

protocol NewDataServiceProtocol {
    func downloadItemWithEscaping(completion: @escaping (_ items: [String]) -> Void)
    func downloadItemWithCombine() -> AnyPublisher<[String], Error>
}

class NewMockDataService: NewDataServiceProtocol {
    let items: [String]
    init(items: [String]?) {
        self.items = items ?? ["one", "two", "three"]
    }
    func downloadItemWithEscaping(completion: @escaping (_ items: [String]) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            completion(self.items)
        }
    }

    func downloadItemWithCombine() -> AnyPublisher<[String], Error> {
        Just(items)
            .tryMap({ publishedItems in
                guard !publishedItems.isEmpty else { throw URLError(.badServerResponse) }
                return publishedItems
            })
            .eraseToAnyPublisher()
    }
}

class UnitTestingBootcampViewModel: ObservableObject {
    @Published var isPremium: Bool
    @Published var dataArray: [String] = []
    @Published var selectedItem: String? = nil
    let dataService: NewDataServiceProtocol
    var cancellables = Set<AnyCancellable>()

    init(isPremium: Bool, dataService: NewDataServiceProtocol = NewMockDataService(items: nil)) {
        self.isPremium = isPremium
        self.dataService = dataService
    }

    func addItem(item: String) {
        guard !item.isEmpty else { return }
        self.dataArray.append(item)
    }

    func selectItem(item: String) {
        if let x = dataArray.first(where: { $0 == item}) {
            selectedItem = x
        } else {
            selectedItem = nil
        }
    }

    func saveItem(item: String) throws {
        guard !item.isEmpty else { throw DataError.noData }
        if let x = dataArray.first(where: { $0 == item}) {
            print("Saved: \(x)")
        } else {
            throw DataError.itemNotFound
        }
    }

    func downloadItemsWithEscaping() {
        dataService.downloadItemWithEscaping { [weak self] items in
            self?.dataArray = items
        }
    }

    func downloadItemsWithCombine() {
        dataService.downloadItemWithCombine()
            .sink { _ in

            } receiveValue: { [weak self] items in
                self?.dataArray = items
            }
            .store(in: &cancellables)
    }

    enum DataError: Error {
        case noData
        case itemNotFound
    }
}
