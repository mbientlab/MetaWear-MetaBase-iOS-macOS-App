//
//  ConfigTableViewCell.swift
//  MetaBase
//
//  Created by Stephen Schiffli on 2/5/16.
//  Copyright © 2016 MBIENTLAB, INC. All rights reserved.
//

import UIKit

protocol ConfigTableViewCellDelegate {
    func configTableViewCellEnableChanged(_ cell: ConfigTableViewCell)
    func configTableViewCellCanChangeFreq(_ cell: ConfigTableViewCell) -> Bool
}

class ConfigTableViewCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var iconImage: UIImageView!
    @IBOutlet weak var adjustmentSlider: UISlider!
    @IBOutlet weak var xImage: UIImageView!
    @IBOutlet weak var checkImage: UIImageView!
    @IBOutlet weak var adjustmentLabel: UILabel!
    @IBOutlet weak var enabledSwitch: UISwitch!
    @IBOutlet weak var rangeSlider: UISlider!
    @IBOutlet weak var rangeLabel: UILabel!
    
    var delegate: ConfigTableViewCellDelegate?
    var remaining: ConfigTableViewCellDelegate?

    var config: SensorConfig? {
        didSet {
            if let config = config {
                nameLabel.text = config.name.uppercased()
                iconImage.image = UIImage(named: config.iconName)
                
                if config.values.count < 2 {
                    adjustmentSlider.isHidden = true
                    adjustmentLabel.text = config.values[0]
                } else {
                    adjustmentSlider.isHidden = false
                    adjustmentSlider.maximumValue = max(0, Float(config.values.count - 1))
                    adjustmentSlider.value = Float(config.selectedIdx ?? 0)
                    adjustmentLabel.text = config.values[Int(round(adjustmentSlider.value))]
                }
                if config.rangeValues != nil {
                    rangeSlider.maximumValue = max(0, Float(config.rangeValues!.count - 1))
                    rangeSlider.value = Float(config.selectedRangeIdx ?? 0)
                    rangeLabel.text = config.rangeValues![Int(round(rangeSlider.value))]
                    rangeSliderDone(rangeSlider)
                }
                
                if config.selectedIdx == nil {
                    enabledSwitch.isOn = false
                    checkImage.alpha = 0.0
                    xImage.alpha = 1.0
                } else {
                    enabledSwitch.isOn = true
                    checkImage.alpha = 1.0
                    xImage.alpha = 0.0
                }
                // There is a timestamp hazard if using only async events like shock and lilt, so
                // we force the usage of the temperature sensor in all cases
                if Constants.isTracker && config.name == "TEMPERATURE" {
                    enabledSwitch.isEnabled = false
                }
            }
        }
    }
    
    func disableSensor() {
        config?.selectedIdx = nil
    
        enabledSwitch.isOn = false
        checkImage.alpha = 0.0
        xImage.alpha = 1.0
    }
    
    @IBAction func adjustmentSliderDone(_ sender: Any) {
        guard let config = config else {
            return
        }
        let idx = Int(round(adjustmentSlider.value))
        if enabledSwitch.isOn {
            let prevIdx = config.selectedIdx ?? 0
            config.selectedIdx = idx
            if let ans = self.delegate?.configTableViewCellCanChangeFreq(self) {
                if !ans {
                    config.selectedIdx = prevIdx
                    adjustmentSlider.value = Float(prevIdx)
                    adjustmentLabel.text = config.values[prevIdx]
                }
            }
        }
    }
    
    @IBAction func adjustmentSliderChanged(_ sender: UISlider) {
        guard let config = config else {
            return
        }
        let idx = Int(round(adjustmentSlider.value))
        adjustmentLabel.text = config.values[idx]
    }
    
    @IBAction func rangeSliderChanged(_ sender: UISlider) {
        guard let config = config else {
            return
        }
        let idx = Int(round(rangeSlider.value))
        rangeLabel.text = config.rangeValues![idx]
    }
    
    @IBAction func rangeSliderDone(_ sender: Any) {
        guard let config = config else {
            return
        }
        let idx = Int(round(rangeSlider.value))
        config.selectedRangeIdx = idx
    }
    
    @IBAction func enabledChanged(_ sender: UISwitch) {
        guard let config = config else {
            return
        }
        if enabledSwitch.isOn {
            config.selectedIdx = Int(round(adjustmentSlider.value))
        } else {
            config.selectedIdx = nil
        }
        
        if enabledSwitch.isOn {
            UIView.animate(withDuration: 0.25, animations: {
                self.checkImage.alpha = 1.0
                self.xImage.alpha = 0.0
            }, completion: { done in
                self.delegate?.configTableViewCellEnableChanged(self)
            })
        } else {
            UIView.animate(withDuration: 0.25, animations: {
                self.checkImage.alpha = 0.0
                self.xImage.alpha = 1.0
            }, completion: { done in
                self.delegate?.configTableViewCellEnableChanged(self)
            })
        }
    }
}
