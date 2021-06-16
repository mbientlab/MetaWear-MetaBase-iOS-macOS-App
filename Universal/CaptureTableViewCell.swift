//
//  CaptureTableViewCell.swift
//  MetaBase
//
//  Created by Stephen Schiffli on 3/21/18.
//  Copyright © 2018 MBIENTLAB, INC. All rights reserved.
//

import UIKit
import MetaWear


class CaptureTableViewCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var buttonActivity: UIActivityIndicatorView!
    @IBOutlet weak var buttonCheckImage: UIImageView!
    @IBOutlet weak var progress: UIProgressView!
    
    func updateUI(_ _progress: DownloadProgress) {
        nameLabel.text = _progress.device.metadata.name
        progress.progress = Float(_progress.prevProgress)
        
        if _progress.device.isConnectedAndSetup || _progress.finished {
            buttonActivity.stopAnimating()
            buttonCheckImage.isHidden = false
        } else {
            buttonActivity.startAnimating()
            buttonCheckImage.isHidden = true
        }
    }
}
