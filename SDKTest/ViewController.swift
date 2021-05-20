//
//  ViewController.swift
//  SDKTest
//
//  Created by Sansi Mac on 2021/5/20.
//

import UIKit
import PlayerSDK
class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        let crc = Crc16.computeChecksum(on: [0x02,0x00,0x06,0x01,0x32,0x34,0x03], startingAt: 0, length: 7)
        print("crc16", crc)
//        HsuFPSView.shared.startMonitoring()
//        HsuFontHandler.shared.setupFont()
        ShareManager.shared.getCurrentProgrameList { (list) in
            print(list)
        }
        // Do any additional setup after loading the view.
    }
}

