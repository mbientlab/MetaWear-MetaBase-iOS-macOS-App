//
//  DeviceDetailTableViewCell.swift
//  MetaBase
//
//  Created by Stephen Schiffli on 2/16/18.
//  Copyright © 2018 MBIENTLAB, INC. All rights reserved.
//

import UIKit
import MetaWear

class DeviceDetailTableViewCell: MainTableViewCell {
    @IBOutlet weak var batteryIcon: UIImageView!
    
    override func updateAll() {
        DispatchQueue.main.async {
            self.updateMac()
            self.updateName()
            self.updateSignalImage()
            self.updateBattery()
        }
    }
    
    func updateBattery() {
        if device.metadata.battery < 25 {
            batteryIcon.image = #imageLiteral(resourceName: "battery0")
        } else if device.metadata.battery < 50 {
            batteryIcon.image = #imageLiteral(resourceName: "battery1")
        } else if device.metadata.battery < 75 {
            batteryIcon.image = #imageLiteral(resourceName: "battery2")
        } else {
            batteryIcon.image = #imageLiteral(resourceName: "battery3")
        }
    }
}
