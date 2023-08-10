//
//  Elm.swift
//  SmartOBD2
//
//  Created by kemo konteh on 8/5/23.
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

class ELMComm: ObservableObject {
    var obdProtocol: ELM327.PROTOCOL = .NONE //Will be determined by the setup
    private var readyToSend = true
    @Published var currentSetupStepReady = true
    
    @Published var ecuCount = 0
    private var setupInProgress = false
    private var setupTimer: Timer?
    fileprivate var parserResponse: (Bool, [String]) = (false, [])
    fileprivate var numberOfDTCs: Int = 0
    fileprivate let parser = OBDParser.sharedInstance
    
    private var Ble: BluetoothViewModel
    fileprivate var requestingDTCs: Bool = false
    fileprivate var getDTCsStatus: ELM327.QUERY.GET_DTCS_STEP = .none
    fileprivate var currentDTCs: [String] = []
    fileprivate var currentGetDTCsQueryReady = false
    fileprivate var getDTCsTimer: Timer?
    fileprivate var rpmTimer: Timer?
    fileprivate var supportedPIDs: [String:[String]] = [:]
    
    
    
    init(Ble: BluetoothViewModel) {
        self.Ble = Ble
    }
    
    var currentQuery = ELM327.QUERY.Q_ATD
    var setupStatus = ELM327.QUERY.SETUP_STEP.send_ATD
    
    func setupAdapter(){
        if setupInProgress {
            return
        }
        self.setupTimer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(setupTimedQueries), userInfo: nil, repeats: true)
        //Start the setup by sending ATD to the adapter the rest will be done by the timedFunc and the response evaluator
        self.setupInProgress = true
        self.currentQuery = .Q_ATD
        self.setupStatus = .send_ATD
    }
    
    @objc func setupTimedQueries(){
        
        if(readyToSend && currentSetupStepReady){
            currentSetupStepReady = false
            
            switch (setupStatus) {
            case .send_ATD: self.currentQuery = .Q_ATD; Ble.sendMessage("ATD", logMessage: "ATD");
            case .send_ATZ: self.currentQuery = .Q_ATZ; Ble.sendMessage("ATZ", logMessage: "ATZ");
            case .send_ATE0: self.currentQuery = .Q_ATE0; Ble.sendMessage("ATE0", logMessage: "ATE0");
            case .send_ATH0_1: self.currentQuery = .Q_ATH0; Ble.sendMessage("ATH0", logMessage: "ATH0_1");
            case .send_ATH1_1: self.currentQuery = .Q_ATH1; Ble.sendMessage("ATH1", logMessage: "ATH1_1");
            case .send_ATDPN: self.currentQuery = .Q_ATDPN; Ble.sendMessage("ATDPN", logMessage: "ATDPN");
            case .send_ATSPC: self.currentQuery = .Q_ATSPC; Ble.sendMessage("ATSP7", logMessage: "ATSPC");
            case .send_ATSPB: self.currentQuery = .Q_ATSPB; Ble.sendMessage("ATSPB", logMessage: "ATSPB");
            case .send_ATSPA: self.currentQuery = .Q_ATSPA; Ble.sendMessage("ATSPA", logMessage: "ATSPA");
            case .send_ATSP9: self.currentQuery = .Q_ATSP9; Ble.sendMessage("ATSP9", logMessage: "ATSP9");
            case .send_ATSP8: self.currentQuery = .Q_ATSP8; Ble.sendMessage("ATSP8", logMessage: "ATSP8");
            case .send_ATSP7: self.currentQuery = .Q_ATSP7; Ble.sendMessage("ATSP7", logMessage: "ATSP7");
            case .send_ATSP6: self.currentQuery = .Q_ATSP6; Ble.sendMessage("ATSP6", logMessage: "ATSP6");
            case .send_ATSP5: self.currentQuery = .Q_ATSP5; Ble.sendMessage("ATSP5", logMessage: "ATSP5");
            case .send_ATSP4: self.currentQuery = .Q_ATSP4; Ble.sendMessage("ATSP4", logMessage: "ATSP4");
            case .send_ATSP3: self.currentQuery = .Q_ATSP3; Ble.sendMessage("ATSP3", logMessage: "ATSP3");
            case .send_ATSP2: self.currentQuery = .Q_ATSP2; Ble.sendMessage("ATSP2", logMessage: "ATSP2");
            case .send_ATSP1: self.currentQuery = .Q_ATSP1; Ble.sendMessage("ATSP1", logMessage: "ATSP1");
            case .send_ATSP0: self.currentQuery = .Q_ATSP0; Ble.sendMessage("ATSP0", logMessage: "ATSP0");
            case .send_ATH1_2: self.currentQuery = .Q_ATH1; Ble.sendMessage("ATH1", logMessage: "ATH1_2");
            case .send_ATH0_2: self.currentQuery = .Q_ATH0; Ble.sendMessage("ATH0", logMessage: "ATH0_2");
            case .test_SELECTED_PROTOCOL_1: self.currentQuery = .Q_0100; Ble.sendMessage("0100", logMessage: "0100") //Progress stays the same
            case .test_SELECTED_PROTOCOL_2: self.currentQuery = .Q_0100; Ble.sendMessage("0100", logMessage: "0100") //Progress stays the same
            case .test_SELECTED_PROTOCOL_FINISHED: self.setupStatus = .send_ATH1_2; self.currentSetupStepReady = true;
            case .finished:
                self.setupInProgress = false
                self.setupTimer!.invalidate()
                requestDTCs()
            case .none:
                break
            }
        }
    }
    
    func decodeSupportedPIDs(responseData: String) -> [String] {
        print("data: \(responseData)")
        
        // Convert the response data from hexadecimal to binary
        let binaryData = Array(responseData)
            .compactMap { $0.hexDigitValue }
            .map { String($0, radix: 2).leftPadding(toLength: 8, withPad: "0") }
            .joined()
        
        
        // Define the supported PIDs based on the binary representation
        let supportedPIDs = binaryData.enumerated()
            .compactMap { index, bit -> String? in
                if bit == "1" {
                    let pidNumber = String(format: "%02X", index + 1)
                    return pidNumber
                }
                return nil
            }
        
        return supportedPIDs
    }
    
    
    func getSupportedPIDs(response: [String]) {
        if readyToSend {
            currentQuery = .Q_0100
            Ble.sendMessage("0100", logMessage: "0100")
            
            let linesAsStr = linesToStr(response)
            print("Lines as str: \(linesAsStr)")
            
            let ecuSegments = linesAsStr.components(separatedBy: "18 DA F1")
            
            // The first element of splitLines will be an empty string since the input starts with the pattern
            
            for ecuSegment in ecuSegments.dropFirst() {
                let ecuData = String(ecuSegment.dropFirst(2)) // Remove the "10" prefix
                
                let ecuDataArray = linesToStrArray([ecuSegment]).dropLast()
                
                // Convert the ECU data from hexadecimal to binary
                let binaryData = Array(ecuData)
                    .compactMap { $0.hexDigitValue }
                    .map { String($0, radix: 2).leftPadding(toLength: 8, withPad: "0") }
                    .joined()
                if ecuDataArray.count >= 8 && ecuDataArray[0] == "10" {
                    let ecuName = "Engine Control"
                    let supportedPIDsArray = Array(ecuDataArray[4...7])
                    let supportedPIDs = decodeSupportedPIDs(responseData: supportedPIDsArray.joined())
                    print("Supported PIDs for \(ecuName): \(supportedPIDs)")
                }
            }
        }
    }
    
    
    func decodeRPM(response: String) {
        let pattern = "([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})555555"
        let range = response.range(of: pattern, options: .regularExpression)
        
        //         Process the pattern occurrence in the buffer
        guard let matchedRange = range else {
            return
            
        }
        let rpmData = response[matchedRange]
        
        guard let rpmValue = UInt(rpmData.prefix(4), radix: 16) else {
            print("Invalid RPM value")
            return
            
        }
        print("RPM: \(rpmValue)")
        return
    }
    
    func startRequest(characteristic: CBCharacteristic, peripheral: CBPeripheral) {
        //            Make sure the RPM timer is stopped before starting a new one
        stopRequest()
        
        //            Start a new timer to send RPM requests every X seconds
        rpmTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Ble.sendMessage("010C", logMessage: "010C")
        }
    }
    
    func stopRequest() {
        rpmTimer?.invalidate()
        rpmTimer = nil
    }
    
    func evaluateResponse(response: [String]){
        if setupInProgress {
            if (setupStatus == .send_ATD      ||
                setupStatus == .send_ATZ      ||
                setupStatus == .send_ATE0     ||
                setupStatus == .send_ATH0_1   ||
                setupStatus == .send_ATH1_1   ||
                setupStatus == .send_ATDPN    ||
                setupStatus == .send_ATH1_2   ||
                setupStatus == .send_ATH0_2   ){
                
                if (parserResponse.0){
                    if(setupStatus == .send_ATH0_2 ){
                        setupStatus = .finished
                    }else{
                        setupStatus = setupStatus.next()
                    }
                }else {
                    setupStatus = .none
                    print("Error")
                    return
                }
                
            }
            
            else if (setupStatus == .send_ATSPC){setupStatus = setupStatus.next();obdProtocol = .PC}
            else if  (setupStatus == .send_ATSPB){setupStatus = setupStatus.next();obdProtocol = .PB}
            else if  (setupStatus == .send_ATSPA){setupStatus = setupStatus.next();obdProtocol = .PA}
            else if  (setupStatus == .send_ATSP9){setupStatus = setupStatus.next();obdProtocol = .P9}
            else if  (setupStatus == .send_ATSP8){setupStatus = setupStatus.next();obdProtocol = .P8}
            else if  (setupStatus == .send_ATSP7){setupStatus = setupStatus.next();obdProtocol = .P7}
            else if  (setupStatus == .send_ATSP6){setupStatus = setupStatus.next();obdProtocol = .P6}
            else if  (setupStatus == .send_ATSP5){setupStatus = setupStatus.next();obdProtocol = .P5}
            else if  (setupStatus == .send_ATSP4){setupStatus = setupStatus.next();obdProtocol = .P4}
            else if  (setupStatus == .send_ATSP3){setupStatus = setupStatus.next();obdProtocol = .P3}
            else if  (setupStatus == .send_ATSP2){setupStatus = setupStatus.next();obdProtocol = .P2}
            else if  (setupStatus == .send_ATSP1){setupStatus = setupStatus.next();obdProtocol = .P1}
            else if  (setupStatus == .send_ATSP0){setupStatus = setupStatus.next();obdProtocol = .P0}
            
            //Test selected protocol by sending 0100  two times
            else if(setupStatus == .test_SELECTED_PROTOCOL_1 || setupStatus == .test_SELECTED_PROTOCOL_2){
                switch setupStatus {
                    
                case .test_SELECTED_PROTOCOL_1:
                    if parserResponse.0 {
                        setupStatus = .test_SELECTED_PROTOCOL_FINISHED
                    }else {
                        setupStatus = setupStatus.next()
                    }
                case .test_SELECTED_PROTOCOL_2:
                    
                    if parserResponse.0 {
                        
                        setupStatus = .test_SELECTED_PROTOCOL_FINISHED
                        
                    } else if(obdProtocol != .P0){
                        
                        obdProtocol = obdProtocol.nextProtocol()
                        
                        switch obdProtocol {
                        case .PB: setupStatus = .send_ATSPB
                        case .PA: setupStatus = .send_ATSPA
                        case .P9: setupStatus = .send_ATSP9
                        case .P8: setupStatus = .send_ATSP8
                        case .P7: setupStatus = .send_ATSP7
                        case .P6: setupStatus = .send_ATSP6
                        case .P5: setupStatus = .send_ATSP5
                        case .P4: setupStatus = .send_ATSP4
                        case .P3: setupStatus = .send_ATSP3
                        case .P2: setupStatus = .send_ATSP2
                        case .P1: setupStatus = .send_ATSP1
                        case .P0: setupStatus = .send_ATSP0
                        default: break
                            
                        }
                    } else {
                        setupStatus = .none
                        return
                    }
                default:
                    break
                }
            }
            else if(setupStatus == .test_SELECTED_PROTOCOL_FINISHED) {
                setupStatus = .send_ATH1_2
            }
            self.currentSetupStepReady = true
        } else if(self.requestingDTCs) {
            
            switch self.getDTCsStatus {
                
            case .send_0101: // CHECK HOW MANY DTCs are stored in the vehicle
                if(numberOfDTCs != 0){
                    
                    getDTCsStatus = .send_03
                    
                } else {
                    print("NO DTCS TO ASK FOR")
                    return
                }
            case .send_03:
                self.currentDTCs = self.parserResponse.1
                if(currentDTCs.count > 0){
                    getDTCsStatus = .finished
                } else {
                    print("NO DTCS")
                    getDTCsStatus = .none
                    return
                }
            case .finished:
                break
            case .none:
                break
            }
            self.currentGetDTCsQueryReady = true
        }
    }
    
    func requestDTCs(){
        if requestingDTCs {
            return
        }
        
        self.getDTCsTimer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(self.requestDTCsTimedFunc), userInfo: nil, repeats: true)
        //Start the setup by sending ATD to the adapter the rest will be done by the timedFunc and the response evaluator
        self.requestingDTCs = true
        self.currentQuery = .Q_0101
        self.getDTCsStatus = .send_0101
        Ble.sendMessage("0101", logMessage: "0101")
    }
    
    
    @objc func requestDTCsTimedFunc(){
        
        if(readyToSend && currentGetDTCsQueryReady){
            currentGetDTCsQueryReady = false
            
            switch (getDTCsStatus) {
            case .send_0101: self.currentQuery = .Q_0101; Ble.sendMessage("0101", logMessage: "0101")
            case .send_03: self.currentQuery = .Q_03; Ble.sendMessage("03", logMessage: "0101")
            case .finished: self.currentQuery = .NONE
                self.requestingDTCs = false
                //Kill the timer if the protocol has been determined
                self.getDTCsTimer!.invalidate()
            case .none:
                break
            }
        }
    }
    
    func parseResponse(response: [String]){
        let linesAsStr = linesToStr(response)
        
        switch self.currentQuery {
            
        case .Q_ATD, .Q_ATE0, .Q_ATH0, .Q_ATH1, .Q_ATSPC, .Q_ATSPB, .Q_ATSPA,
                .Q_ATSP9, .Q_ATSP8, .Q_ATSP7, .Q_ATSP6, .Q_ATSP5, .Q_ATSP4, .Q_ATSP3,
                .Q_ATSP2, .Q_ATSP1, .Q_ATSP0:
            if linesAsStr.contains("OK") {
                parserResponse = (true,[])
                evaluateResponse(response: response)
                
            } else {
                parserResponse = (false, [])
                evaluateResponse(response: response)
                
            }
        case .Q_ATZ:
            parserResponse = (true, []) // TODO
            evaluateResponse(response: response)
        case .Q_ATDPN:
            // protocol description
            parserResponse = (true, []) // TODO
            evaluateResponse(response: response)
        case .Q_0100:
            if linesAsStr.contains("41"){
                parserResponse = (true,[])
                evaluateResponse(response: response)
                getSupportedPIDs(response: response)
            } else {
                parserResponse = (false, [])
                evaluateResponse(response: response)
            }
        case .Q_0101:
            numberOfDTCs = parser.parse_0101(response, obdProtocol: obdProtocol)
            evaluateResponse(response: response)
        case .Q_03:
            parserResponse = parser.parseDTCs(self.numberOfDTCs, linesToParse: response, obdProtocol: self.obdProtocol)
            evaluateResponse(response: response)
        case .Q_0902:
            parserResponse = (false, [])
        case .Q_07:
            parserResponse = (false, [])
        default:
            parserResponse = (false, [])
        }
    }
    
    
}
