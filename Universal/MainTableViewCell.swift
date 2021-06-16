//
//  MainTableViewCell.swift
//  MetaBase
//
//  Created by Stephen Schiffli on 2/15/18.
//  Copyright © 2018 MBIENTLAB, INC. All rights reserved.
//

import UIKit
import MetaWear

class MainTableViewCell: BaseTableViewCell {
    var adWatchdog: Timer?
    override var device: MetaWear! {
        didSet {
            updateAll()
            device.advertisementReceived = { [weak self] in
                guard let strongSelf = self else {
                    return
                }
                DispatchQueue.main.async {
                    strongSelf.updateAll()
                    strongSelf.adWatchdog?.invalidate()
                    strongSelf.adWatchdog = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] t in
                        guard let strongSelf = self else {
                            return
                        }
                        strongSelf.updateAll()
                    }
                }
            }
        }
    }
}
