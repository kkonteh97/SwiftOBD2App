//
//  BleCommTest.swift
//  SMARTOBD2Tests
//
//  Created by kemo konteh on 10/18/23.
//

import XCTest
@testable import SMARTOBD2
import Combine

// Naming Structure: test_UnitOfWork_StateUnderTest_ExpectedBehavior
// Naming Structure: test_[struct or class]_[variable or function]_[expected result]

// Testing Struture: Given, When, Then

final class UnitTestingBootcampViewModelTest: XCTestCase {
    var viewModel: UnitTestingBootcampViewModel?
    var cancellables = Set<AnyCancellable>()

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        viewModel = UnitTestingBootcampViewModel(isPremium: Bool.random())
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        viewModel = nil
    }

    func test_UnitTestingBootcampViewModel_isPremium_shouldBeTrue() {
        // Given
        let userIsPremium: Bool = true
        // When
        let vm = UnitTestingBootcampViewModel(isPremium: userIsPremium)
        // Then
        XCTAssertTrue(vm.isPremium)
    }

    func test_UnitTestingBootcampViewModel_isPremium_shouldBeFalse() {
        // Given
        let userIsPremium: Bool = false
        // When
        let vm = UnitTestingBootcampViewModel(isPremium: userIsPremium)
        // Then
        XCTAssertFalse(vm.isPremium)
    }

    func test_UnitTestingBootcampViewModel_isPremium_shouldBeInjectedValue() {
        // Given
        let userIsPremium: Bool = Bool.random()
        // When
        let vm = UnitTestingBootcampViewModel(isPremium: userIsPremium)
        // Then
        XCTAssertEqual(userIsPremium, vm.isPremium)
    }

    func test_UnitTestingBootcampViewModel_isPremium_shouldBeInjectedValue_stress() {
        for _ in 0..<100 {
            // Given
            let userIsPremium: Bool = Bool.random()
            // When
            let vm = UnitTestingBootcampViewModel(isPremium: userIsPremium)
            // Then
            XCTAssertEqual(userIsPremium, vm.isPremium)
        }
    }

    func test_UnitTestingBootcampViewModel_dataArray_shouldBeEmpty() {
        // Given
        guard let vm = viewModel else {
            XCTFail("View model should not be nil")
            return
        }
        // When

        // Then
        XCTAssertTrue(vm.dataArray.isEmpty)
        XCTAssertEqual(vm.dataArray.count, 0)
    }

    func test_UnitTestingBootcampViewModel_dataArray_shouldAddItems() {
        // Given
        let vm = UnitTestingBootcampViewModel(isPremium: Bool.random())

        // When
        let loopCount = Int.random(in: 1...100)
        for _ in 0..<loopCount {
            vm.addItem(item: UUID().uuidString)
        }
        // Then
        XCTAssertTrue(!vm.dataArray.isEmpty)
        XCTAssertEqual(vm.dataArray.count, loopCount)
        XCTAssertGreaterThan(vm.dataArray.count, 0)
    }

    func test_UnitTestingBootcampViewModel_dataArray_shouldNotAddBlackString() {
        // Given
        let vm = UnitTestingBootcampViewModel(isPremium: Bool.random())

        // When
        vm.addItem(item: "")
        // Then
        XCTAssertTrue(vm.dataArray.isEmpty)
    }

    func test_UnitTestingBootcampViewModel_dataArray_shouldStartAsNil() {
        // Given

        // When
        let vm = UnitTestingBootcampViewModel(isPremium: Bool.random())

        // Then
        XCTAssertTrue(vm.selectedItem == nil)
        XCTAssertNil(vm.selectedItem)
    }

    func test_UnitTestingBootcampViewModel_dataArray_shouldNilWhenSelectingInvalidItem() {
        // Given
        let vm = UnitTestingBootcampViewModel(isPremium: Bool.random())

        // When
        vm.selectItem(item: UUID().uuidString)

        // Then
        XCTAssertNil(vm.selectedItem)
    }

    func test_UnitTestingBootcampViewModel_save_should_throwNoDataError_itemNotFound() {
        // Given
        let vm = UnitTestingBootcampViewModel(isPremium: Bool.random())

        // When
        let loopCount = Int.random(in: 1...100)
        for _ in 0..<loopCount {
            vm.addItem(item: UUID().uuidString)
        }

        // Then
        XCTAssertThrowsError(try vm.saveItem(item: ""), "Should throw no data error!") { error in
            let returnError = error as? UnitTestingBootcampViewModel.DataError
            XCTAssertEqual(returnError, UnitTestingBootcampViewModel.DataError.noData)
        }
        XCTAssertThrowsError(try vm.saveItem(item: UUID().uuidString), "Should throw item Not error!") { error in
            let returnError = error as? UnitTestingBootcampViewModel.DataError
            XCTAssertEqual(returnError, UnitTestingBootcampViewModel.DataError.itemNotFound)

        }
    }

    func test_UnitTestingBootcampViewModel_downloadItemsWithEscaping_should_returnItems() {
        // Given
        let vm = UnitTestingBootcampViewModel(isPremium: Bool.random())

        // When
        let expectation = XCTestExpectation(description: "Download items")
        vm.$dataArray
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)

        vm.downloadItemsWithEscaping()

        // Then
        wait(for: [expectation], timeout: 5.0)
        XCTAssertNotNil(vm.dataArray)
        XCTAssertTrue(!vm.dataArray.isEmpty)

    }

    func test_UnitTestingBootcampViewModel_downloadItemsWithCombine_should_returnItems() {
        // Given
        let vm = UnitTestingBootcampViewModel(isPremium: Bool.random())

        // When
        let expectation = XCTestExpectation(description: "Download items")

        vm.$dataArray
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)

        vm.downloadItemsWithCombine()

        // Then
        wait(for: [expectation], timeout: 5.0)

        XCTAssertNotNil(vm.dataArray)
        XCTAssertTrue(!vm.dataArray.isEmpty)
    }
}
