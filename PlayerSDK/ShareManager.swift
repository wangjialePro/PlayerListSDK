//
//  ShareManager.swift
//  BeijingBankLed
//
//  Created by Sansi Mac on 2018/8/29.
//  Copyright © 2021年 王家乐. All rights reserved.
//

import UIKit
import AVFoundation


public class ShareManager: NSObject{
    public static let shared = ShareManager()
    open var playerIP = "192.168.1.100"
    var progromList = [Program]() //当前播放列表
    var currentPrograme = Program.init() //当前播放内容
    var currentIndex = 0   // 播放序列
    var playServerStatus = 0 // 服务端状态
    var timer = Timer() //定时器
    override init() {
    super.init()
    }
    open func makeTimer(){
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { (timer) in
            
        })
    }
    open func destoryTimer() {
        timer.invalidate()
    }
    open func getCurrentProgrameList(result:@escaping(([String])->Void)){
        result(["界面1","界面2","界面3"])
    }
}

class Program: NSObject {
    var index = 0
    var name = ""
    var hex = ""
    override init() {
    super.init()
    
    }
}
