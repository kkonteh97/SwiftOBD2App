//
//  BleConnectionTest.swift
//  SMARTOBD2Tests
//
//  Created by kemo konteh on 10/18/23.
//

import XCTest
@testable import SMARTOBD2

final class BleConnectionTest: XCTestCase {
    var mockCentralManager: CBCentralManagerMock!
    var mockPeripheral: CBPeripheralProtocol!
    var bleManager: BLEManager!
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        mockCentralManager = CBCentralManagerMock(delegate: nil, queue: nil)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_BLEManager_init() {
        // Given

        // When
        let bleManger = BLEManager()
        // Then
    }

}
