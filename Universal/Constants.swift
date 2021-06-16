//
//  Constants.swift
//  MetaBase
//
//  Created by Stephen Schiffli on 4/24/17.
//  Copyright © 2017 MBIENTLAB, INC. All rights reserved.
//

import UIKit
import MetaWearCpp

struct Constants {
    static let streamUpdateInterval = 1.0
    static let scanTimeoutSeconds = 5.0
    static let documentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let applicationSupportDirectory = FileManager().urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    static let pendingDirectory = documentsDirectory.appendingPathComponent("pending", isDirectory: true)
    static let archivePath = applicationSupportDirectory.appendingPathComponent("metadata").path
    static let dateFormatter: DateFormatter = {
        let x = DateFormatter()
        x.dateFormat = "yyyy-MM-dd'T'HH.mm.ss.SSS"
        return x
    }()
    #if TRACKER
        static let isTracker = true
        static let cloudName = "MetaTracker"
        static let magicByte1: UInt8 = 0x74
        static let oldNameStartingIdx = 12
        static let buttonColor = UIColor(red: 0x50 / 255.0, green: 0xA2 / 255.0, blue: 0xEB / 255.0, alpha: 1.0)
        static let maxNameLength = 16
        static let magicByte2: UInt8 = 0x03
        static let nameStartingIdx = 13
    #else
        static let isTracker = false
        static let cloudName = "MetaCloud"
        static let oldMagicByte1: UInt8 = 0x62
        static let oldNameStartingIdx = 2
        static let buttonColor = UIColor(red: 0x23 / 255.0, green: 0xCD / 255.0, blue: 0x6E / 255.0, alpha: 1.0)
        static let maxNameLength = 26
        static let magicByte2: UInt8 = 0x02
        static let nameStartingIdx = 3
    #endif
    static let oldMagicByte0: UInt8 = 0x6D
    static let magicByte0: UInt8 = 0x7E
    static let magicByte1: UInt8 = 0x06
}

extension String {
    var documentDirectoryUrl: URL {
        get {
            return Constants.documentsDirectory.appendingPathComponent(self)
        }
    }
}

extension UIColor {
    class var mtbSilverColor: UIColor {
        return UIColor(red: 182.0 / 255.0, green: 200.0 / 255.0, blue: 196.0 / 255.0, alpha: 0.3)
    }
    
    class var mtbAlgaeGreenColor: UIColor {
        return UIColor(red: 35.0 / 255.0, green: 205.0 / 255.0, blue: 110.0 / 255.0, alpha: 1.0)
    }
    
    class var mtbRedColor: UIColor {
        return UIColor(red: 204.0 / 255.0, green: 0.0 / 255.0, blue: 0.0 / 255.0, alpha: 1.0)
    }
}
