//
//  Data+Extension.swift
//  BitStream
//
//  Created by myself on 2019/5/25.
//  Copyright © 2019 chaocaiwei. All rights reserved.
//

import Foundation

func toByteArray<T>(value: T) -> [UInt8] {
    var value = value
    let bytes = withUnsafeBytes(of: &value,{$0.map({$0})})
    return bytes
}

func byteArrayToType<T>(_ value:[UInt8]) -> T
{
    return value.withUnsafeBytes({$0.load(as:T.self)})
}

extension UInt8 {
    var hexString : String {
        let str = String(format:"0x%02x",self)
        return str
    }
}

extension FixedWidthInteger {
    var bytes : [UInt8] {
        let size =  self.bitWidth / 8 // MemoryLayout<Self>.size
        if size == 1 {
            return [UInt8(self)]
        }
        var bytes = [UInt8]()
        for i in 0..<size {
            let distance = (size - 1 - i) * 8;
            let sub  = self >> distance
            let value = UInt8(sub & 0xff)
            bytes.append(value)
        }
        return bytes
    }
    
    var hexString : String {
        var str = ""
        for byte in self.bytes {
            str = str.appendingFormat("0x%02x ", byte)
        }
        return str
    }
    
}

func add<T:FixedWidthInteger>(toBuf:inout [UInt8],_ value:T){
    let size = MemoryLayout<T>.size
    for i in 1...size {
        let distance = (size - i) * 8;
        let sub  = (value >> distance) & 0xff
        let value = UInt8(sub & 0xff)
        toBuf.append(value)
    }
}

extension Data {
    var bytes : [UInt8] {
        return [UInt8](self)
    }
    var hexString : String {
        var str = ""
        for byte in self.bytes {
            str += byte.hexString
            str += " "
        }
        return str
    }
}
