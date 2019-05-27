//
//  ViewController.swift
//  BitStream
//
//  Created by myself on 2019/5/25.
//  Copyright © 2019 chaocaiwei. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    
    override func viewDidLoad() {
        super.viewDidLoad()
        swiftTest()
        OCTest.test()
    }
    
    func swiftTest(){
        let data0 = buildDataWithBufferPointer()
        print(data0.hexString)
        let data = buildDataWithBytes()
        print(data.hexString)
        testParse(mdata:data)
        testParseInSwift5(mdata:data)
        testParseWithBytes(mdata:data)
        print("一个字符串".bytes)
        testStruct()
    }
    
    func buildDataWithBytes()->Data{
        var mbytes = [UInt8]()
        mbytes.append(UInt8(3))
        mbytes += 0x1234567890.bytes
        mbytes += toByteArray(value:3.14)
        mbytes += "a string".bytes
        let mdata = Data(mbytes)
        return mdata
    }
    
    func buildDataWithBufferPointer()->Data {
        var a = 3.bigEndian
        var b = UInt16(23).bigEndian
        var e : Double = 3.14
        var data = Data(bytes:&a, count:a.bitWidth/8)
        let bpoint = UnsafeBufferPointer(start:&b, count:1)
        data.append(bpoint)
        data.append(UnsafeBufferPointer(start:&e, count:1))
        return data
    }
    
    func testParseInSwift5(mdata:Data){
        let mc0 = mdata[0]
        let mdata1 = Data(mdata[1..<9])
        let mi0 = mdata1.withUnsafeBytes {$0.load(as:UInt64.self)}
        let rmi0 = mi0.bigEndian
        let md0 =  Data(mdata[9..<17]).withUnsafeBytes {  $0.load(as: Double.self) }
        let ms0 = String(data:mdata[17..<mdata.count], encoding:.utf8)
        print("mc0=\(mc0) rmi0=\(rmi0) md0=\(md0) ms0=\(ms0 ?? "")")
    }
    
    func testParse(mdata:Data){
        let mc : UInt8  =  mdata[0]
        let tmi : Int    =  mdata[1..<9].withUnsafeBytes {$0.pointee}
        let mi : Int     = tmi.bigEndian
        let md : Double  = mdata[9..<17].withUnsafeBytes {$0.pointee}
        let ms  = String(data:mdata[17..<mdata.count], encoding:.utf8)
        print("mc=\(mc) mi=\(mi) md=\(md) ms=\(ms ?? "")")
    }
    
    func testParseWithBytes(mdata:Data){
        let bytes = [UInt8](mdata)
        let ma : UInt8 = bytes[0]
        let mb = bytes[1..<9].enumerated().reduce(0, { (result, arg) -> Int in
            let (offset, item) = arg
            let size = MemoryLayout<Int>.size
            let biteOffset = (size - offset - 1) * 8
            let temp =  Int(item) << biteOffset
            return result | temp
        })
        let mc : Double = byteArrayToType(bytes[9..<17].map({$0}))
        
        print("ma=\(ma) mb=\(mb) mc=\(mc)")
    }
    
    
    
}

struct Some {
    var age : UInt8? = 18
    var a : UInt8? = 2
    var b : UInt16? = 0x0102
    var name = "name"
}
