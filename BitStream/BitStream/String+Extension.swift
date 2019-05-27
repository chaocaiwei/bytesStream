//
//  String+Extension.swift
//  BitStream
//
//  Created by myself on 2019/5/26.
//  Copyright © 2019 chaocaiwei. All rights reserved.
//

import Foundation


extension String {
    var bytes : [UInt8] {
       var bytes = self.cString(using:.utf8)?.map({ char -> UInt8 in
            if char < 0 {
                let b = char & 0b01111111
                let c = UInt8(b) | 0b10000000
                return c
            }else{
                return UInt8(char)
            }
        })
        bytes = bytes?.dropLast()
        return bytes ?? [UInt8]()
    }
}
