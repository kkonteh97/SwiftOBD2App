//
//  CANProtocol.swift
//  SmartOBD2
//
//  Created by kemo konteh on 9/16/23.
//

import Foundation

class CANProtocol: OBDPROTOCOL {
    let TX_ID_ENGINE = 0
    let TX_ID_TRANSMISSION = 1
    
    let FRAME_TYPE_SF: UInt8 = 0x00  // single frame
    let FRAME_TYPE_FF: UInt8 = 0x10  // first frame of multi-frame message
    let FRAME_TYPE_CF: UInt8 = 0x20  // consecutive frame(s) of multi-frame message
    
    var idBits: Int
    var lines0100: [String]

    override init(lines0100: [String], idBits: Int) {
        self.lines0100 = lines0100
        self.idBits = idBits
        super.init(lines0100: lines0100, idBits: idBits)
    }

    override func parseFrame(_ frame: Frame) -> Bool {
            var raw = frame.raw

            // pad 11-bit CAN headers out to 32 bits for consistency,
            // since ELM already does this for 29-bit CAN headers

            //        7 E8 06 41 00 BE 7F B8 13
            // to:
            // 00 00 07 E8 06 41 00 BE 7F B8 13

            if idBits == 11 {
                raw = "00000" + raw
            }

            // Handle odd size frames and drop
            if raw.count % 2 != 0 {
                print("Dropping frame for being odd")
                return false
            }

            let rawBytes = raw.hexBytes

            // check for valid size

            if rawBytes.count < 6 {
                // make sure that we have at least a PCI byte, and one following byte
                // for FF frames with 12-bit length codes, or 1 byte of data
                print("Dropped frame for being too short")
                return false
            }

            if rawBytes.count > 12 {
                print("Dropped frame for being too long")
                return false
            }

            // read header information
            if idBits == 11 {
                // Ex.
                //       [   ]
                // 00 00 07 E8 06 41 00 BE 7F B8 13

                frame.priority = rawBytes[2] & 0x0F  // always 7
                frame.addrMode = rawBytes[3] & 0xF0  // 0xD0 = functional, 0xE0 = physical

                if frame.addrMode == 0xD0 {
                    // untested("11-bit functional request from tester")
                    frame.rxID = rawBytes[3] & 0x0F  // usually (always?) 0x0F for broadcast
                    frame.txID = 0xF1  // made-up to mimic all other protocols
                } else if (rawBytes[3] & 0x08) != 0 {
                    frame.rxID = 0xF1  // made-up to mimic all other protocols
                    frame.txID = rawBytes[3] & 0x07
                } else {
                    // untested("11-bit message header from tester (functional or physical)")
                    frame.txID = 0xF1  // made-up to mimic all other protocols
                    frame.rxID = rawBytes[3] & 0x07
                }

            } else {  // idBits == 29:
                frame.priority = rawBytes[0]  // usually (always?) 0x18
                frame.addrMode = rawBytes[1]  // DB = functional, DA = physical
                frame.rxID = rawBytes[2]  // 0x33 = broadcast (functional)
                frame.txID = rawBytes[3]  // 0xF1 = tester ID
            }

            // extract the frame data
            //             [      Frame       ]
            // 00 00 07 E8 06 41 00 BE 7F B8 13
            frame.data = Data(rawBytes[4...])


            // read PCI byte (always first byte in the data section)
            //             v
            // 00 00 07 E8 06 41 00 BE 7F B8 13
            frame.type = frame.data[0] & 0xF0
            if ![FRAME_TYPE_SF, FRAME_TYPE_FF, FRAME_TYPE_CF].contains(frame.type) {
                print("Dropping frame carrying unknown PCI frame type")
                return false
            }

            if frame.type == FRAME_TYPE_SF {
                // single frames have 4 bit length codes
                //              v
                // 00 00 07 E8 06 41 00 BE 7F B8 13
                frame.dataLen = UInt8(frame.data[0] & 0x0F)

                // drop frames with no data
                if frame.dataLen == 0 {
                    return false
                }

            } else if frame.type == FRAME_TYPE_FF {
                // First frames have 12 bit length codes
                //              v vv
                // 00 00 07 E8 10 20 49 04 00 01 02 03
                frame.dataLen = UInt8((UInt16(frame.data[0] & 0x0F) << 8) + UInt16(frame.data[1]))

                // drop frames with no data
                if frame.dataLen == 0 {
                    return false
                }

            } else if frame.type == FRAME_TYPE_CF {
                // Consecutive frames have 4 bit sequence indices
                //              v
                // 00 00 07 E8 21 04 05 06 07 08 09 0A
                frame.seqIndex = frame.data[0] & 0x0F
            }

            return true
    }
    
    func isContiguous(_ indice: [UInt8]) -> Bool {
        var last = indice[0]
        for i in indice {
            if i != last + 1 {
                return false
            }
            last = i
        }
        return true
    }

    

    
    override func parseMessage(_ message: Message) -> Bool {
            let frames = message.frames

            if frames.count == 1 {
                let frame = frames[0]

                if frame.type != FRAME_TYPE_SF {
                    print("Received lone frame not marked as single frame")
                    return false
                }

                // extract data, ignore PCI byte and anything after the marked length
                //             [      Frame       ]
                //                [     Data      ]
                // 00 00 07 E8 06 41 00 BE 7F B8 13 xx xx xx xx, anything else is ignored
                message.data = Data(frame.data[1..<(1 + Int(frame.dataLen!))])

            } else {
                // sort FF and CF into their own lists

                var ff: [Frame] = []
                var cf: [Frame] = []

                for f in frames {
                    if f.type == FRAME_TYPE_FF {
                        ff.append(f)
                    } else if f.type == FRAME_TYPE_CF {
                        cf.append(f)
                    } else {
                        print("Dropping frame in multi-frame response not marked as FF or CF")
                    }
                }

                // check that we captured only one first-frame
                if ff.count > 1 {
                    print("Received multiple frames marked FF")
                    return false
                } else if ff.isEmpty {
                    print("Never received frame marked FF")
                    return false
                }

                // check that there was at least one consecutive-frame
                if cf.isEmpty {
                    print("Never received frame marked CF")
                    return false
                }

                // calculate proper sequence indices from the lower 4 bits given
                for i in 0..<(cf.count - 1) {
                    let prev = cf[i]
                    let curr = cf[i + 1]
                    // Frame sequence numbers only specify the low order bits, so compute the
                    // full sequence number from the frame number and the last sequence number seen:
                    // 1) take the high order bits from the lastSN and low order bits from the frame
                    var seq = (prev.seqIndex & ~0x0F) + curr.seqIndex
                    // 2) if this is more than 7 frames away, we probably just wrapped (e.g.,
                    // last=0x0F current=0x01 should mean 0x11, not 0x01)
                    if seq < prev.seqIndex - 7 {
                        // untested
                        seq += 0x10
                    }

                    curr.seqIndex = seq
                }

                // sort the sequence indices
                cf.sort { $0.seqIndex < $1.seqIndex }

                // check contiguity, and that we aren't missing any frames
                let indices = cf.map { $0.seqIndex }
                if !isContiguous(indices) {
                    print("Received multiline response with missing frames")
                    return false
                }

                // first frame:
                //             [       Frame         ]
                //             [PCI]                   <-- first frame has a 2 byte PCI
                //              [L ] [     Data      ] L = length of message in bytes
                // 00 00 07 E8 10 13 49 04 01 35 36 30

                // consecutive frame:
                //             [       Frame         ]
                //             []                       <-- consecutive frames have a 1 byte PCI
                //              N [       Data       ]  N = current frame number (rolls over to 0 after F)
                // 00 00 07 E8 21 32 38 39 34 39 41 43
                // 00 00 07 E8 22 00 00 00 00 00 00 31

                // original data:
                // [     specified message length (from first-frame)      ]
                // 49 04 01 35 36 30 32 38 39 34 39 41 43 00 00 00 00 00 00 31

                // on the first frame, skip PCI byte AND length code
                message.data = ff[0].data[2...]

                // now that they're in order, load/accumulate the data from each CF frame
                for f in cf {
                    message.data += f.data[1...]  // chop off the PCI byte
                }

                // chop to the correct size (as specified in the first frame)
                let endIndex = message.data.startIndex + Int(ff[0].dataLen!)
                message.data = message.data[..<endIndex]
            }

            // trim DTC requests based on DTC count
            // this ISN'T in the decoder because the legacy protocols
            // don't provide a DTC_count bytes, and instead, insert a 0x00
            // for consistency

            if message.data[0] == 0x43 {
                //    []
                // 43 03 11 11 22 22 33 33
                //       [DTC] [DTC] [DTC]

                let numDTCBytes = Int(message.data[1]) * 2  // each DTC is 2 bytes
                message.data = Data(message.data.prefix(numDTCBytes + 2))  // add 2 to account for mode/DTC_count bytes
            }

            return true
        }
}

