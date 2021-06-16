//
//  BaseTableViewCell.swift
//  MetaBase
//
//  Created by Stephen Schiffli on 2/15/18.
//  Copyright © 2018 MBIENTLAB, INC. All rights reserved.
//

import UIKit
import MetaWear

class BaseTableViewCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var idLabel: UILabel!
    @IBOutlet weak var signalImage: UIImageView!
    @IBOutlet weak var recordingIcon: UIView!
    
    var normalFont: UIFont?
    var italicFont: UIFont?
    var device: MetaWear!
    
    func updateAll() {
        DispatchQueue.main.async {
            self.updateMac()
            self.updateName()
            self.updateSignalImage()
            self.updateRecordingIcon()
        }
    }
    
    func updateName() {
        nameLabel.text = device.metadata.name
        nameLabel.textColor = device.isMetaBoot ? UIColor.mtbRedColor : UIColor.black
    }
    
    func updateMac() {
        if italicFont == nil {
            normalFont = idLabel.font
            let fd = idLabel.font.fontDescriptor.withSymbolicTraits(.traitItalic) ?? idLabel.font.fontDescriptor
            italicFont = UIFont(descriptor: fd, size: idLabel.font.pointSize)
        }
        idLabel.text = device.mac ?? "Connect for MAC"
        idLabel.font = (device.mac != nil) ? normalFont : italicFont
    }
    
    func updateSignalImage() {
        if let movingAverage = device.averageRSSI(lastNSeconds: Constants.scanTimeoutSeconds) {
            if (movingAverage < -80.0) {
                signalImage.image = #imageLiteral(resourceName: "signal 5")
            } else if movingAverage < -65.0 {
                signalImage.image = #imageLiteral(resourceName: "signal 4")
            } else if movingAverage < -50.0 {
                signalImage.image = #imageLiteral(resourceName: "signal 3")
            } else if movingAverage < -40.0 {
                signalImage.image = #imageLiteral(resourceName: "signal 2")
            } else {
                signalImage.image = #imageLiteral(resourceName: "signal 1")
            }
        } else {
            signalImage.image = #imageLiteral(resourceName: "signal 6")
        }
    }
    
    func updateRecordingIcon() {
        recordingIcon.isHidden = !device.isConfigured
    }
}

