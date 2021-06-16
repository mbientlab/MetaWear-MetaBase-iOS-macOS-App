//
//  GroupTableViewCell.swift
//  MetaBase
//
//  Created by Stephen Schiffli on 2/15/18.
//  Copyright © 2018 MBIENTLAB, INC. All rights reserved.
//

import UIKit
import MetaWear

class GroupTableViewCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var recordingIcon: UIView!
    
    var devices: [MetaWear]! {
        didSet {
            devices.forEach { $0.advertisementReceived = { [weak self] in self?.updateRecordingIcon() } }
        }
    }
    
    func updateRecordingIcon() {
        DispatchQueue.main.async {
            self.recordingIcon.isHidden = self.devices.contains { !$0.isConfigured }
        }
    }
}

