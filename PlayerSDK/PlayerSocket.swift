//
//  playerSocket.swift
//  VP_Montage
//
//  Created by Sansi Mac on 2019/3/20.
//  Copyright © 2019 zhouqitian. All rights reserved.
//

import UIKit
class PlayerSocket: NSObject ,GCDAsyncSocketDelegate{
    let timer = Timer()
    var playerSocket:GCDAsyncSocket!
    var changeProgrameblock:((_ success:Bool)->Void)?
    var getStatusBlcok:((_ status:Int)->Void)?
    var connectStatus = 0  //MARK:0 正在连接   1 连接成功！   2 断开连接
    var read_play_status = "00"//0--正常播放，1--暂停播放，2--停止播放）
    let XML_HEX = "2e786d6c" //.xml 后缀处理
    let GET_PLAYLIST = Data(bytes: [0x02, 0x05, 0x00, 0xff, 0xf5, 0x03])
    let GET_CURRENT_PLAY = Data(bytes: [0x02, 0x04, 0x40, 0x84, 0x03])
    let GET_CURRENT_STATUS = Data(bytes: [0x02, 0xc2, 0xf9, 0x0e, 0x03])
    let PLAY = Data(bytes: [0x02, 0xc1, 0x01, 0x35, 0x44, 0x03])
    let STOP = Data(bytes: [0x02, 0xc1, 0x00, 0x25, 0x65, 0x03])
    override init() {
        super.init()
        self.initSocketV3()
        Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { (timer) in
                if self.playerSocket.isConnected == false {
                    self.connectplayerSocket()
                    sleep(UInt32(0.2))
                }
                if self.connectStatus == 1 {
                    self.playerSocket.write(self.GET_CURRENT_PLAY, withTimeout: 1, tag: 2)
                    self.readPlayStatus()
                }
            }
    }
    //MARK:切节目
    func switchTargetPrograme(program: Program){
        let nameData = self.playTargetProgram(program: program)
        if self.connectStatus == 1 {
            self.playerSocket.write(nameData, withTimeout: 2, tag: 2)
        }else{
            self.connectplayerSocket()
            sleep(UInt32(0.2))
            self.playerSocket.write(nameData, withTimeout: 2, tag: 2)
        }
    }
    func refreshV3Action(){
        print(self.connectStatus, self.playerSocket.isConnected)
        if self.playerSocket.isConnected == false {
            self.connectplayerSocket()
            sleep(UInt32(0.2))
        }else{
            self.getProgramList()
        }
    }
    //MARK:获取节目单
    func getProgramList(){
        self.playerSocket.write(GET_PLAYLIST, withTimeout: 1, tag: 1)
    }
    //MARK:初始化socket
    func initSocketV3(){
        if (playerSocket == nil) {
            playerSocket = GCDAsyncSocket.init()
            playerSocket.delegate = self
            playerSocket.delegateQueue = DispatchQueue.main
        }
        self.connectplayerSocket()
    }
    //MARK:connect
    func connectplayerSocket(){
        do {
            try playerSocket.connect(toHost: ShareManager.shared.playerIP, onPort:7211, withTimeout: -1)
        } catch {
            print("conncet player error")
        }
    }
    //MARK:delegate
    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        self.connectplayerSocket()
        self.connectStatus =  2
        ShareManager.shared.playServerStatus = 2
    }
    
    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        self.connectStatus = 1
        ShareManager.shared.playServerStatus = 1
        playerSocket.readData(withTimeout: -1, tag: 0)
        self.getProgramList()
        self.readPlayStatus()
        
    }
    
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        var result = data.hexEncodedString()
        if result.count > 4{
            let index3 = result.index(result.startIndex, offsetBy: 2)
            let index4 = result.index(result.startIndex, offsetBy: 4)
            result = String(result[index3..<index4])
            if result == "05" {
                if ShareManager.shared.progromList.count > 0 {
                }else{
                    ShareManager.shared.progromList = self.getPlayerProgrameList(data: data)
                    NotificationCenter.default.post(name: NSNotification.Name.init("refreshTable"), object: nil)
                }
            }else if(result=="04"){
                ShareManager.shared.currentPrograme = self.getCurrentPlayPrograme(data: data, list: ShareManager.shared.progromList)
                NotificationCenter.default.post(name: NSNotification.Name.init("refreshTable"), object: nil)

            }else if(result=="c2"){
                 //MARK:获取播放状态
                self.read_play_status =  self.getPlayerProgrameStatus(data: data)
                NotificationCenter.default.post(name: NSNotification.Name.init("refreshTable"), object: nil)

            }else if(result=="c1"){
                //MARK:设置播放状态
                self.read_play_status =  self.getPlayerProgrameStatus(data: data)
                NotificationCenter.default.post(name: NSNotification.Name.init("refreshTable"), object: nil)

            }else{
                 self.changeProgrameblock!(true)
            }
        }
        playerSocket.readData(withTimeout: -1, tag: 0)
        
    }
    func socket(_ sock: GCDAsyncSocket, didReceive trust: SecTrust, completionHandler: @escaping (Bool) -> Void) {
        playerSocket.readData(withTimeout: -1, tag: 0)
    }
    //
    func switchProgramNext(isNext:Bool){
     
        if isNext {
       ShareManager.shared.currentIndex += 1
            if ShareManager.shared.currentIndex == ShareManager.shared.progromList.count {
                ShareManager.shared.currentIndex = 0
            }
        }else{
        ShareManager.shared.currentIndex -= 1
            if ShareManager.shared.currentIndex == -1 {
                ShareManager.shared.currentIndex = ShareManager.shared.progromList.count-1
            }
        }
        self.switchTargetPrograme(program: ShareManager.shared.progromList[ShareManager.shared.currentIndex])
        
    }
     //MARK:获取播放状态  0--正常播放，1--暂停播放，2--停止播放
    func readPlayStatus(){
        self.playerSocket.write(self.GET_CURRENT_STATUS, withTimeout: 0.5, tag: 4)
    }
    func setPlayStatus(){
        if self.read_play_status == "00" {
            self.playerSocket.write(self.PLAY, withTimeout: 0.5, tag: 8)
        }else{
            self.playerSocket.write(self.STOP, withTimeout: 0.5, tag: 8)
            
        }
    }
}
extension PlayerSocket{
    func bytes(from hexStr: String) -> [UInt8] {
            assert(hexStr.count % 2 == 0, "输入字符串格式不对，8位代表一个字符")
            var bytes = [UInt8]()
            var sum = 0
            // 整形的 utf8 编码范围
            let intRange = 48...57
            // 小写 a~f 的 utf8 的编码范围
            let lowercaseRange = 97...102
            // 大写 A~F 的 utf8 的编码范围
            let uppercasedRange = 65...70
            for (index, c) in hexStr.utf8CString.enumerated() {
                var intC = Int(c.byteSwapped)
                if intC == 0 {
                    break
                } else if intRange.contains(intC) {
                    intC -= 48
                } else if lowercaseRange.contains(intC) {
                    intC -= 87
                } else if uppercasedRange.contains(intC) {
                    intC -= 55
                } else {
                    assertionFailure("输入字符串格式不对，每个字符都需要在0~9，a~f，A~F内")
                }
                sum = sum * 16 + intC
                // 每两个十六进制字母代表8位，即一个字节
                if index % 2 != 0 {
                    bytes.append(UInt8(sum))
                    sum = 0
                }
            }
            return bytes
    }
//    获取播放表
    func getPlayerProgrameList(data: Data) -> [Program]{
        var listString = data.hexEncodedString()
        let start = listString.index(listString.startIndex, offsetBy: 4)
        let end = listString.index(listString.startIndex, offsetBy: listString.count - 6)
        listString = String(listString[start..<end])
        print(listString)
        let listArray = listString.components(separatedBy: "00")
        var list = [Program]()
        for (index, item) in listArray.enumerated() {
            if item.count > 2 {
                let data = Data.init(bytes: self.bytes(from: item))
                let name = String.init(data: data, encoding: .utf8) ?? "未识别节目"
                let program = Program.init()
                program.index = index
                program.name = name
                program.hex = item
                list.append(program)
            }
        }
        return list
    }
    /**
     获取当前播放表播放节目
     */
    func getCurrentPlayPrograme(data: Data,list:[Program]) -> Program {
        var listString = data.hexEncodedString()
        let start = listString.index(listString.startIndex, offsetBy: 4)
        let end = listString.index(listString.startIndex, offsetBy: listString.count - 6)
        listString = String(listString[start..<end])
        let listArray = listString.components(separatedBy: "00")
        var currentHex = ""
        for name in listArray {
            if name.hasSuffix(XML_HEX) {
                currentHex = String(name.prefix(name.count - 8))
            }
        }
        let program = Program.init()
        for item in list {
            if item.hex == currentHex {
                let data = Data.init(bytes: self.bytes(from: currentHex))
                let name = String.init(data: data, encoding: .utf8) ?? "未识别节目"
                program.name = name
                program.hex = currentHex
            }
        }
        return program
    }
    
}
extension Data {
    // 转data为 16 进制的字符串
    func hexEncodedString() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
}
extension String {
    func hexStringConverToData() -> Data {
        var hexString = self
        var data = Data()
        while !hexString.isEmpty {
            guard let index = hexString.index(hexString.startIndex, offsetBy: 2, limitedBy: hexString.endIndex) else {
                break
            }
            let unit = String(hexString[..<index])
            hexString = String(hexString[index..<hexString.endIndex])
            var ch: UInt64 = 0
            Scanner(string: unit).scanHexInt64(&ch)
            var char = UInt8(ch)
            data.append(&char, count: 1)
        }
        
        return data
    }
}
extension PlayerSocket{
    func judgePostCodeWithStr(crc: String) -> [UInt8] {
        var content = [UInt8]([0x02, 0x06, 0x00])
        let bytes = [UInt8](crc.hexStringConverToData())
        for byte in bytes {
            if byte == 2 {
                content.append(0x1B)
                content.append(0xE7)
            }else if byte == 3 {
                content.append(0x1B)
                content.append(0xE8)
            }else if byte == 27 {
                content.append(0x1B)
                content.append(0x00)
            }else{
                content.append(byte)
            }

        }
        content.append(0x03)
        return content
    }
//     播放节目
    func playTargetProgram(program: Program)-> Data{
        let centerData = ("0600" + program.hex).hexStringConverToData()
        let crc = Crc16Ccitt.computeChecksum(with: Crc16InitialValue.x0000, on:[UInt8](centerData))
        let dataStr = program.hex + String(format: "%0X", crc)
        let contentData = self.judgePostCodeWithStr(crc: dataStr)
        return Data.init(bytes: contentData)
    }
//    获取播放状态
    func getPlayerProgrameStatus(data: Data) ->  String{
        var status = ""
        var contentBytes = [UInt8]([])
        let bytes = [UInt8](data)
        for (index, byte) in bytes.enumerated() {
            if byte == 27 {
                let nextCode = bytes[index+1]
                if nextCode == 121{
                    contentBytes.append(0x02)
                }else if nextCode == 122 {
                    contentBytes.append(0x03)
                }else if nextCode == 0 {
                    contentBytes.append(byte)
                }
            }else{
                contentBytes.append(byte)
            }
        }
        status = contentBytes[3] == 0 ? "00":"01"
        return status
    }
}
