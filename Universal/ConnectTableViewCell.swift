//
//  ConnectTableViewCell.swift
//  MetaBase
//
//  Created by Stephen Schiffli on 2/5/16.
//  Copyright © 2016 MBIENTLAB, INC. All rights reserved.
//

import UIKit
import MetaWear

class ConnectTableViewCell: BaseTableViewCell {
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var buttonActivity: UIActivityIndicatorView!
    
    var model: ScannerModelItem! {
        didSet {
            device = model.device
            model.stateDidChange = { [weak self] in
                DispatchQueue.main.async {
                    self?.updateMac()
                    self?.updateName()
                    self?.updateSignalImage()
                    self?.updateConnectButton()
                }
            }
        }
    }
    
    func updateConnectButton() {
        if model.isConnecting {
            buttonActivity.startAnimating()
            connectButton.setTitle("", for: UIControl.State())
            signalImage.isHidden = true
        } else {
            buttonActivity.stopAnimating()
            connectButton.setTitle("connect", for: UIControl.State())
            signalImage.isHidden = model.device.isConnectedAndSetup
        }
        connectButton.isEnabled = model.connectButtonEnabled
    }
    
    @IBAction func connectPressed(_ sender: UIButton) {
        model.toggleConnect()
    }
}


