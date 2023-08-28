//
//  ELMSetup.swift
//  SmartOBD2
//
//  Created by kemo konteh on 8/18/23.
//

import Foundation





extension BLEManager {
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
    
    func setupAdapter() async{
        if setupInProgress {
            return
        }
//        self.setupTimer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(setupTimedQueries), userInfo: nil, repeats: true)
        //Start the setup by sending ATD to the adapter the rest will be done by the timedFunc and the response evaluator
        self.setupInProgress = true
        self.setupStatus = .send_ATD
    }
    
    @objc func setupTimedQueries() {
        
        if(readyToSend && currentSetupStepReady){
            currentSetupStepReady = false
            
            switch (setupStatus) {
                
                case .send_ATD, .send_ATE1, .send_ATH0, .send_ATH1, .send_ATSTFF, .send_ATL0, .send_ATAT1: 


                sendMessage(self.setupStatus.rawValue, logMessage: self.setupStatus.rawValue){ message, response in
                    guard let response = response else {
                        return
                    }
                    if response.contains("OK") {
                        self.setupStatus = self.setupStatus.next()
                        self.currentSetupStepReady = true
                        
                    }
                }
                    
                case .send_ATDPN: sendMessage(self.setupStatus.rawValue, logMessage: "ATD"){ message, response in
                    guard let response = response else {
                        return
                    }
                    let protocolPart = response.split(separator: "").last
                    let protocolString = String(protocolPart ?? "none")
                    
                    self.obdProtocol = ELM327.fromResponseNumber(protocolString)
                    print(self.obdProtocol)
                    
                    self.setupStatus = self.obdProtocolSetupStatus(for: self.obdProtocol)
                    self.currentSetupStepReady = true
                }
                    
                case .send_ATZ: sendMessage(self.setupStatus.rawValue, logMessage: "ATD"){ message, response in
                    guard let _ = response else {
                        return
                    }
                    self.setupStatus = self.setupStatus.next()
                    self.currentSetupStepReady = true
                }
                    
                case .send_ATSPC, .send_ATSPB, .send_ATSPA, .send_ATSP9, .send_ATSP8, .send_ATSP7, .send_ATSP6, .send_ATSP5, .send_ATSP4, .send_ATSP3, .send_ATSP2, .send_ATSP1, .send_ATSP0:
                    sendMessage(self.setupStatus.rawValue, logMessage: "ATD"){ message, response in
                        guard let response = response else {
                            return
                        }
                        if !response.contains("OK") {
                            return
                        }
                        switch self.setupStatus {
                        case .send_ATSPC: self.obdProtocol = .PC
                        case .send_ATSPB: self.obdProtocol = .PB
                        case .send_ATSPA: self.obdProtocol = .PA
                        case .send_ATSP9: self.obdProtocol = .P9
                        case .send_ATSP8: self.obdProtocol = .P8
                        case .send_ATSP7: self.obdProtocol = .P7
                        case .send_ATSP6: self.obdProtocol = .P6
                        case .send_ATSP5: self.obdProtocol = .P5
                        case .send_ATSP4: self.obdProtocol = .P4
                        case .send_ATSP3: self.obdProtocol = .P3
                        case .send_ATSP2: self.obdProtocol = .P2
                        case .send_ATSP1: self.obdProtocol = .P1
                        case .send_ATSP0: self.obdProtocol = .P0
                                default: break
                        }
                        self.setupStatus = self.setupStatus.next()
                        self.currentSetupStepReady = true
                    }
                    
                // has to be done with header on to get ecu numbers
                case .test_SELECTED_PROTOCOL_1: sendMessage("0100", logMessage: "0100"){ [self] message, response in
                    guard let response = response else {
                        self.currentSetupStepReady = true
                        if message.contains("Timeout") {
                            self.setupStatus = self.setupStatus.next()
                        }
                        return
                    }
                    
                    if response.contains("41"){
                        guard let ecus = self.getECUs(response: response) else { return }
                        print(ecus)
                        self.setupStatus = self.setupStatus.next()
                    }
                    self.currentSetupStepReady = true
                }
                case .send_ATCRA: sendMessage(self.craFilter, logMessage: "ATD"){ message, response in
                    guard let response = response else {
                        return
                    }
                    if response.contains("OK") {
                        self.setupStatus = self.setupStatus.next()
                        self.currentSetupStepReady = true
                        
                    }
                }
                case .test_SELECTED_PROTOCOL_2: sendMessage("0100", logMessage: "0100"){ [self] message, response in
                    guard let response = response else {
                        self.currentSetupStepReady = true
                        if message.contains("Timeout") {
                            self.obdProtocol = obdProtocol.nextProtocol()

                            self.setupStatus = self.obdProtocolSetupStatus(for: self.obdProtocol)
                        }
                        return
                    }
                    
                    if response.contains("41"){
                        self.getSupportedPIDs(response: response)
                        self.setupStatus = self.setupStatus.next()
                    }
                    self.currentSetupStepReady = true
                }
                    
                    
                case .send_0902:
                    sendMessage("0902", logMessage: "0902"){ message, response in
                    guard let response = response else {
                        self.currentSetupStepReady = true
                        return
                    }

                    if response.contains("49"){
                        self.setupStatus = self.decodeVIN(for: self.setupStatus, response: (true, [response])) ?? .none
                    }
                    self.currentSetupStepReady = true


                }
                                
                
                
            case .test_SELECTED_PROTOCOL_FINISHED: self.setupStatus = .finished; self.currentSetupStepReady = true;
                case .finished:
                    print("Setup Complete")
                    self.setupInProgress = false
                    self.setupTimer!.invalidate()
                    self.initialized = true
                    
                case .none:
                    break
          
            }
        }
    }
    
    func obdProtocolSetupStatus(for obdProtocol: ELM327.PROTOCOL) -> ELM327.QUERY.SETUP_STEP {
        
        switch obdProtocol {
        case .PC: return .send_ATSPC
        case .PB: return .send_ATSPB
        case .PA: return .send_ATSPA
        case .P9: return .send_ATSP9
        case .P8: return .send_ATSP8
        case .P7: return .send_ATSP7
        case .P6: return .send_ATSP6
        case .P5: return .send_ATSP5
        case .P4: return .send_ATSP4
        case .P3: return .send_ATSP3
        case .P2: return .send_ATSP2
        case .P1: return .send_ATSP1
        case .P0: return .send_ATSP0
        case .NONE:
            return .none
        
        }
    }
    
}
