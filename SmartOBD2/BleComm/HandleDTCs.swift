//
//  HandleDTCs.swift
//  SmartOBD2
//
//  Created by kemo konteh on 8/12/23.
//

import Foundation

extension BLEManager {
//    func requestDTCs(){
//        if requestingDTCs {
//            return
//        }
//        
//        self.getDTCsTimer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(self.requestDTCsTimedFunc), userInfo: nil, repeats: true)
//        //Start the setup by sending ATD to the adapter the rest will be done by the timedFunc and the response evaluator
//        self.requestingDTCs = true
//        self.currentQuery = .Q_0101
//        self.getDTCsStatus = .send_0101
////        sendMessage("0101", logMessage: "0101") { message, response in
////        }
//    }
//    
//    
//    @objc func requestDTCsTimedFunc(){
//        
//        if(readyToSend && currentGetDTCsQueryReady){
//            currentGetDTCsQueryReady = false
//            
//            switch (getDTCsStatus) {
//            case .send_0101: self.currentQuery = .Q_0101; sendMessage("0101", logMessage: "0101") { message, response in
//            }
//            case .send_03: self.currentQuery = .Q_03; sendMessage("03", logMessage: "0101") { message, response in
//            }
//            case .finished: self.currentQuery = .NONE
//                self.requestingDTCs = false
//                //Kill the timer if the protocol has been determined
//                self.getDTCsTimer!.invalidate()
//            case .none:
//                break
//            }
//        }
//    }
}
