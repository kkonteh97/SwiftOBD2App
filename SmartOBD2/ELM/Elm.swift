//
//  Elm.swift
//  SmartOBD2
//
//  Created by kemo konteh on 8/5/23.
//

import Foundation
import CoreBluetooth

extension BluetoothViewModel {
    func evaluateResponse(for status: ELM327.QUERY.SETUP_STEP, response: (Bool, [String])) -> ELM327.QUERY.SETUP_STEP? {
        if setupInProgress {
            if let newStatus = getNextSetupStatus(for: setupStatus, with: response) {
                currentSetupStepReady = true
                return newStatus
            
            } else {
                return ELM327.QUERY.SETUP_STEP.none
            }
        }
        return nil
    }
    
    private func getNextSetupStatus(for status: ELM327.QUERY.SETUP_STEP, with response: (Bool, [String])) -> ELM327.QUERY.SETUP_STEP? {
    
        switch status {
            case .send_ATD, .send_ATZ, .send_ATE0, .send_ATH0_1, .send_ATH1_1, .send_ATDPN, .send_ATH1_2, .send_ATH0_2:
                if response.0 {
                    return (status == .send_ATH0_2) ? .finished : status.next()
                } else {
                    print("Error")
                    return nil
                }
            
        case .send_ATSPC, .send_ATSPB, .send_ATSPA, .send_ATSP9, .send_ATSP8, .send_ATSP7, .send_ATSP6, .send_ATSP5, .send_ATSP4, .send_ATSP3, .send_ATSP2, .send_ATSP1, .send_ATSP0:
                setupStatus = status.next()
                switch status {
                        case .send_ATSPC: obdProtocol = .PC
                        case .send_ATSPB: obdProtocol = .PB
                        case .send_ATSPA: obdProtocol = .PA
                        case .send_ATSP9: obdProtocol = .P9
                        case .send_ATSP8: obdProtocol = .P8
                        case .send_ATSP7: obdProtocol = .P7
                        case .send_ATSP6: obdProtocol = .P6
                        case .send_ATSP5: obdProtocol = .P5
                        case .send_ATSP4: obdProtocol = .P4
                        case .send_ATSP3: obdProtocol = .P3
                        case .send_ATSP2: obdProtocol = .P2
                        case .send_ATSP1: obdProtocol = .P1
                        case .send_ATSP0: obdProtocol = .P0
                        default: break
                }
            
                return setupStatus
            
        case .test_SELECTED_PROTOCOL_1, .test_SELECTED_PROTOCOL_2:
            return handleTestSelectedProtocol(for: status, response: response)

        case .test_SELECTED_PROTOCOL_FINISHED:
            return .send_ATH1_2
            
        case .send_0902:
            return decodeVIN(for: status, response: response)
        default:
            return nil
        }
       
    }
    
    

    private func handleTestSelectedProtocol(for status: ELM327.QUERY.SETUP_STEP, response: (Bool, [String])) -> ELM327.QUERY.SETUP_STEP? {
        switch status {
            
        case .test_SELECTED_PROTOCOL_1:
            return response.0 ? .send_0902 : setupStatus.next()

        
        case .test_SELECTED_PROTOCOL_2:
            if response.0 {
                return setupStatus.next()
            } else if obdProtocol != .P0 {
                obdProtocol = obdProtocol.nextProtocol()
                return obdProtocolSetupStatus(for: obdProtocol)
            } else {
                return nil
            }
            

        default:
            return nil
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



class ELMComm: ObservableObject {
    
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
}
    


    

    
    
