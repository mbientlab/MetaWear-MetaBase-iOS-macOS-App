//
//  StreamTableViewCell.swift
//  MetaBase
//
//  Created by Stephen Schiffli on 2/5/16.
//  Copyright © 2016 MBIENTLAB, INC. All rights reserved.
//

import UIKit
import MetaWear

class StreamTableViewCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var idLabel: UILabel!
    @IBOutlet weak var buttonActivity: UIActivityIndicatorView!
    @IBOutlet weak var buttonCheckImage: UIImageView!
    @IBOutlet weak var sampleLabel: UILabel!
    
    func updateUI(_ device: MetaWear, state: [State]) {
        idLabel.text = device.mac ?? "Connect for MAC"
        nameLabel.text = device.metadata.name
        
        sampleLabel.text = String(state.reduce(0) { $0 + $1.sampleCount })
                
        if device.isConnectedAndSetup {
            buttonActivity.stopAnimating()
            buttonCheckImage.isHidden = false
        } else {
            buttonActivity.startAnimating()
            buttonCheckImage.isHidden = true
        }
    }
}
