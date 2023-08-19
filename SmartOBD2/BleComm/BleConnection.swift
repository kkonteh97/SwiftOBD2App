//
//  bleConnection.swift
//  Obd2Scanner
//
//  Created by kemo konteh on 8/3/23.
//

import Foundation
import CoreBluetooth


extension String {
    func leftPadding(toLength: Int, withPad character: Character) -> String {
        let paddingAmount = max(0, toLength - count)
        let padding = String(repeating: character, count: paddingAmount)
        return padding + self
    }
}

class BluetoothViewModel: NSObject, ObservableObject, CBPeripheralDelegate {
    var sendMessageCompletion: ((String, String?) -> Void)?


    var readyToSend = true
    @Published var currentSetupStepReady = true
    @Published var VIN: String = ""
    @Published var carMake: String = ""
    @Published var carModel: String = ""
    @Published var carYear: String = ""
    @Published var carCylinders: String = ""

    @Published var setupInProgress = false
    var setupTimer: Timer?
    fileprivate var parserResponse: (Bool, [String]) = (false, [])
    fileprivate var numberOfDTCs: Int = 0
    
    
    var currentDTCs: [String] = []
    var requestingDTCs: Bool = false
    var currentGetDTCsQueryReady = false
    
    var getDTCsTimer: Timer?
    var rpmTimer: Timer?
    
    static let sharedInstance = BluetoothViewModel()
    
    //ELM327 PROTOCOL
    var obdProtocol: ELM327.PROTOCOL = .NONE //Will be determined by the setup
    var currentQuery = ELM327.QUERY.Q_ATD
    var setupStatus = ELM327.QUERY.SETUP_STEP.send_ATD
    var getDTCsStatus: ELM327.QUERY.GET_DTCS_STEP = .none
    
    //PARSING
    fileprivate let parser = OBDParser.sharedInstance
    @Published var linesToParse: [String] = []
    
    //BLUETOOTH
    private var centralManager: CBCentralManager!
    @Published var connectedPeripheral: CBPeripheral?
    @Published var characteristicsFound: [CBCharacteristic] = []
    @Published var deviceName: String = ""
    @Published var obd2Device: CBPeripheral?
    @Published var peripherals: [CBPeripheral] = []
    @Published var peripheralsNames: [String] = []
    @Published var test: [CBService:[CBCharacteristic]] = [:]
    @Published var ecuCharacteristic: CBCharacteristic?
    
    
    @Published var isBlePower: Bool = false
    @Published var isSearching: Bool = false
    @Published var isConnected: Bool = false
    
    @Published var foundServices: [CBService] = []
    @Published var foundCharacteristics: [CBCharacteristic] = []
    
    private let serviceUUID: CBUUID = CBUUID()

    
    @Published var connected: Bool = false
    @Published var initialized: Bool = false
    
    //OBD2
    
    
    @Published var rpm: Int = 0
    @Published var speed: Int = 0
    @Published var engine_load: Int = 0
    @Published var coolant_temp: Int = 0
    @Published var timing_Advance: Int = 0
    @Published var intake_air_temperature: Int = 0
    @Published var MAF: Int = 0
    @Published var oxygen_Sensor_2: Int = 0
    @Published var time_Since_Engine_start: Int = 0
    @Published var Fuel_system_status: Int = 0
    @Published var Short_term_fuel_trim_Bank_1: Int = 0
    @Published var Short_term_fuel_trim_Bank_2: Int = 0
    @Published var Long_term_fuel_trim_Bank_1: Int = 0
    @Published var Intake_manifold_absolute_pressure: Int = 0
    @Published var throttle_position: Int = 0
    
    
    @Published var command: String = ""


    @Published var history: [String] = []
    
    @Published var supportedPIDsByECU: [String] = []
    
    
    
    @Published var pidDescriptions: [String] = []
    
    private var timeoutTimer: Timer?
    private var pendingMessage: String?
    var requestingPids: Bool = false
    var PIDsReady: Bool = false
    var isProcessingRequest: Bool = false
    var pidRequestQueue: [String] = []

    var requestQueue: [String] = []

        
    

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    
    func sendMessage(_ message: String, logMessage: String = "Sending message", timeout: TimeInterval = 5.0, completion: @escaping (String, String?) -> Void) {
        let message = "\(message)\r"
        print("Sending: \(message)")

        guard let connectedPeripheral = self.connectedPeripheral,
              let ecuCharacteristic = self.ecuCharacteristic,
              let data = message.data(using: .ascii) else {
            print("Error: Missing peripheral or characteristic.")
            completion("Error: Missing peripheral or characteristic.", nil)
            return
        }

        // Store the completion handler
        sendMessageCompletion = completion
        
        // Store the sent message and start a timer if needed
        _ = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false) { _ in
            // Handle timeout
            print("Error: Message sending timed out.")
            self.sendMessageCompletion?("Timeout", nil)
            self.sendMessageCompletion = nil
        }
            
        // Store the sent message and start a timer
        connectedPeripheral.writeValue(data, for: ecuCharacteristic, type: .withResponse)
    }

    
    func requestPids() {

        if requestingPids && initialized {
            return
        }
        self.requestingPids = true
        self.rpmTimer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(setupTimedPIDQueries), userInfo: nil, repeats: true)
    }
    
    @objc func setupTimedPIDQueries() {
        if readyToSend && PIDsReady {
            let pidsGroups = supportedPIDsByECU.chunked(into: 6)
            for group in pidsGroups {
                let pidsStr = group.joined(separator: "")
                let cmd = "01\(pidsStr)"
                print(cmd)
                enqueueMessage(cmd, logMessage: "Enqueuing PID request")
            }
            processNextMessage()
        }
    }
    
    func enqueueMessage(_ message: String, logMessage: String) {
        requestQueue.append(message)
        print(logMessage)
    }
    
    func processNextMessage() {
        guard !isProcessingRequest, let nextMessage = requestQueue.first else {
            return
        }

        sendMessage(nextMessage, logMessage: "Sending PID request") { message, response  in
            
        }
        self.isProcessingRequest = true
        requestQueue.removeFirst()
    }
    
    func messageSentSuccessfully() {
        self.isProcessingRequest = false
        processNextMessage()
    }
    
    func parseResponse(for response: [String])  {
        let linesAsStr = linesToStr(response)
        if self.initialized {
            handlePIDResponse(response: response)
            self.messageSentSuccessfully()
        } else {
            switch self.currentQuery {
                
            case .Q_ATD, .Q_ATE0, .Q_ATH0, .Q_ATH1, .Q_ATSPC, .Q_ATSPB, .Q_ATSPA,
                    .Q_ATSP9, .Q_ATSP8, .Q_ATSP7, .Q_ATSP6, .Q_ATSP5, .Q_ATSP4, .Q_ATSP3,
                    .Q_ATSP2, .Q_ATSP1, .Q_ATSP0:
                if linesAsStr.contains("OK") {
                    guard let setupStatus = evaluateResponse(for: setupStatus,response: (true,[])) else { return }
                    self.setupStatus = setupStatus
                    
                    
                } else {
                    setupStatus = evaluateResponse(for: setupStatus,response: (false, [])) ?? .none
                }
            case .Q_ATZ:
                parserResponse = (true, []) // TODO
                setupStatus = evaluateResponse(for: setupStatus,response: parserResponse) ?? .none
                
            case .Q_ATDPN:
                setupStatus = evaluateResponse(for: setupStatus,response: (true, [])) ?? .none
            case .Q_0100:
                if linesAsStr.contains("41"){
                    setupStatus = evaluateResponse(for: setupStatus, response: (true,[])) ?? .none
                    pidDescriptions = getSupportedPIDs(response: response)
                } else {
                    setupStatus = evaluateResponse(for: setupStatus,response: (false, [])) ?? .none
                }
            case .Q_0101:
                numberOfDTCs = parser.parse_0101(response, obdProtocol: obdProtocol)
                setupStatus = evaluateResponse(for: setupStatus,response: parserResponse) ?? .none
                
            case .Q_03:
                parserResponse = parser.parseDTCs(self.numberOfDTCs, linesToParse: response, obdProtocol: self.obdProtocol)
                
                
            case .Q_0902:
                parserResponse = (true, response.dropLast())
                if linesAsStr.contains("49"){
                    setupStatus = evaluateResponse(for: setupStatus,response: parserResponse) ?? .none
                } else {
                    print("no vin")
                }
                
            case .Q_07:
                parserResponse = (false, [])
                
            default:
                parserResponse = (false, [])
            }
        }
        
        func handlePIDResponse(response: [String]) {
            let string = linesToStr(response)
            let hexValues = string.components(separatedBy: " ").dropLast()
            
            print("hex",hexValues)
            print("hex count",hexValues.count)
            
            var index = hexValues.firstIndex(of: "41") ?? 0
            while index < hexValues.count {
                guard index + 1 < hexValues.count else { continue }
                
                let commandCodeHex = hexValues[index + 1]
                print(commandCodeHex)
                if let commandCode = ELM327.PIDs(rawValue: commandCodeHex) {
                    switch commandCode {
                        
                    case .pid03:
                        if index + 3 < hexValues.count {
                            let fuelSystemStatusStr = (hexValues[index + 2...index + 3]).joined(separator: "")
                            guard let fuelSystemStatus = UInt(fuelSystemStatusStr, radix: 16) else {return}
                            self.Fuel_system_status = Int(fuelSystemStatus)
                        }
                        index += 3
                        
                    case .pid04:
                        if index + 2 < hexValues.count {
                            guard let engineload = UInt(hexValues[index + 2], radix: 16) else {return}
                            self.engine_load = Int(engineload)
                        }
                        index += 2
                        
                    case .pid05:
                        if index + 2 < hexValues.count {
                            guard let coolantValue = UInt(hexValues[index + 2], radix: 16) else {return}
                            self.coolant_temp = Int(coolantValue) - 40
                        }
                        index += 2
                        
                    case .pid06:
                        if index + 2 < hexValues.count {
                            guard let ShorttermfueltrimBank1 = UInt(hexValues[index + 2], radix: 16) else {return}
                            self.Short_term_fuel_trim_Bank_1 = Int(ShorttermfueltrimBank1)
                        }
                        index += 2
                        
                    case .pid07:
                        if index + 2 < hexValues.count {
                            guard let LongtermfueltrimBank1 = UInt(hexValues[index + 2], radix: 16) else {return}
                            self.Long_term_fuel_trim_Bank_1 = Int(LongtermfueltrimBank1)
                        }
                        index += 2
                        
                    case .pid08:
                        if index + 2 < hexValues.count {
                            guard let ShorttermfueltrimBank2 = UInt(hexValues[index + 2], radix: 16) else {return}
                            
                            self.Short_term_fuel_trim_Bank_2 = Int(ShorttermfueltrimBank2)
                        }
                        index += 2
                        
                    case .pid09:
                        if index + 2 < hexValues.count {
                            let coolantValue = hexValues[index + 2]
                            self.coolant_temp = Int(coolantValue)!
                        }
                        index += 2
                        
                    case .pid11:
                        if index + 2 < hexValues.count {
                            guard let throttlePosition = UInt(hexValues[index + 2], radix: 16) else {return}
                            self.throttle_position = Int(throttlePosition)
                        }
                        index += 2
                        
                    case .pid0B:
                        if index + 2 < hexValues.count {
                            guard let IntakeManifoldAbsolutePressure = UInt(hexValues[index + 2], radix: 16) else {return}
                            self.Intake_manifold_absolute_pressure = Int(IntakeManifoldAbsolutePressure)
                            index += 2
                        }
                    case .pid0C:
                        if index + 3 < hexValues.count {
                            guard let rpmValue = UInt(hexValues[index + 2...index + 3].joined(), radix: 16) else {
                                print("Invalid RPM value")
                                return
                            }
                            self.rpm = Int(rpmValue) / 4
                            index += 3
                        }
                    case .pid0E:
                        if index + 2 < hexValues.count {
                            guard let timingAdvance = UInt(hexValues[index + 2], radix: 16) else {return}
                            self.timing_Advance = Int(timingAdvance) / 2 - 64                                  }
                        index += 2
                        
                    case .pid0F:
                        if index + 2 < hexValues.count {
                            guard let intakeAirTemperature = UInt(hexValues[index + 2], radix: 16) else {return}
                            self.intake_air_temperature = Int(intakeAirTemperature)                              }
                        index += 2
                    case .pid10:
                        if index + 4 < hexValues.count {
                            guard let MAF = UInt(hexValues[index + 2...index + 4].joined(), radix: 16) else {return}
                            print("MAF", MAF)
                            self.MAF = Int(MAF)                              }
                        index += 4
                        
                    case .pid13:
                        if index + 2 < hexValues.count {
                            print("02 sensors", hexValues[index + 2])                       }
                        index += 2
                        
                    case .pid15:
                        if index + 4 < hexValues.count {
                            guard let oxygenSensor2 = UInt(hexValues[index + 2...index + 4].joined(), radix: 16) else {return}
                            print("oxygenSensor2", oxygenSensor2)
                            self.oxygen_Sensor_2 = Int(oxygenSensor2)                              }
                        index += 4
                    case .pid1C:
                        if index + 2 < hexValues.count {
                            print("OBD standards this vehicle conforms to", hexValues[index + 2])                             }
                        index += 2
                        
                    case .pid1F:
                        if index + 2 < hexValues.count {
                            guard let timeSinceEnginestart = Int(hexValues[index + 2], radix: 16) else {return}
                            print("timeSinceEnginestart", timeSinceEnginestart)
                            self.time_Since_Engine_start = timeSinceEnginestart
                            
                        }
                        index += 2
                    case .pid0D:
                        if index + 2 < hexValues.count {
                            guard let speedValue = Int(hexValues[index + 2], radix: 16) else {return}
                            print("Speed Value:", speedValue)
                            self.speed = speedValue
                        }
                        index += 2
                        
                    default:
                        index += 2
                    }
                } else {
                    index += 2
                }
            }
        }
    }
    func discoverDescriptors(peripheral: CBPeripheral, characteristic: CBCharacteristic) {
        peripheral.discoverDescriptors(for: characteristic)
    }
    
}



extension BluetoothViewModel: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            // Scan for peripherals if BLE is turned on
            self.centralManager?.scanForPeripherals(withServices: nil)
        case .poweredOff:
            // Alert user to turn on Bluetooth
            break
            
        case .resetting:
            // Wait for next state update and consider logging interruption of Bluetooth service
            break
        case .unauthorized:
            // Alert user to enable Bluetooth permission in app Settings
            break
        case .unsupported:
            // Alert user their device does not support Bluetooth and app will not work as expected
            break
            
        case .unknown:
            // Wait for next state update
            break
        @unknown default:
            fatalError()
        }
    }
    
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        // Check if the peripheral is BLE (advertisement data contains the CBAdvertisementDataIsConnectable key with a value of true)
        if let peripheralName = peripheral.name?.lowercased(), peripheralName.hasPrefix("carly") {
            centralManager.stopScan()
            obd2Device = peripheral
            centralManager.connect(peripheral, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to peripheral: \(peripheral.name ?? "Unnamed")")
        connectedPeripheral = peripheral
        peripheral.delegate = self // Set the delegate of the connected peripheral
        self.connected = true
        self.deviceName = peripheral.name ?? ""
        peripheral.discoverServices(nil) // Start discovering all services of the connected peripheral
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to peripheral: \(peripheral.name ?? "Unnamed")")
        connectedPeripheral = nil
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        self.connected = false
        self.initialized = false
    }
    
    func connect(to peripheral: CBPeripheral) {
        centralManager?.connect(peripheral, options: nil)
    }
    
}
