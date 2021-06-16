//
//  MetaWearExtenstions.swift
//  MetaBase
//
//  Created by Stephen Schiffli on 9/30/17.
//  Copyright © 2017 MBIENTLAB, INC. All rights reserved.
//

import MetaWear
import MetaWearCpp
import CoreBluetooth


extension MetaWear {
    // Exta info for private models
    var modelDescription: String {
        let model = mbl_mw_metawearboard_get_model(board)
        guard model != MBL_MW_MODEL_NA else {
            switch info?.modelNumber {
            case "10"?:
                return "Smilables"
            case "11"?:
                return "Beiersdorf"
            case "12"?:
                return "BlueWillow"
            case "13"?:
                return "Andres"
            case "14"?:
                return "Panasonic"
            case "15"?:
                return "MAS"
            case "16"?:
                return "Palarum"
            default:
                return "Unknown"
            }
        }
        return String(cString: mbl_mw_metawearboard_get_model_name(board))
    }
    
    var scanResponsePayload: String? {
        if let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data {
            if manufacturerData.count >= 3 {
                if manufacturerData[0] == Constants.magicByte0 &&
                    manufacturerData[1] == Constants.magicByte1 &&
                    manufacturerData[2] == Constants.magicByte2 {
                    return String(data: manufacturerData[3..<13], encoding: .ascii)
                }
            }
            if manufacturerData.count >= 2 {
                if manufacturerData[0] == Constants.oldMagicByte0 && manufacturerData[1] == Constants.oldMagicByte1 {
                     return String(data: manufacturerData[2..<12], encoding: .ascii)
                }
            }
        }
        return nil
    }
    
    var isConfigured: Bool {
        get {
            // See if the device is advertising the special packet indicating
            // they are logging and ready to be downloaded
            if let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data {
                if manufacturerData.count >= 3 {
                    if manufacturerData[0] == Constants.magicByte0 &&
                        manufacturerData[1] == Constants.magicByte1 &&
                        manufacturerData[2] == Constants.magicByte2 {
                        // Get and update (or create) the metadata
                        let name = String(data: manufacturerData.suffix(from: Constants.nameStartingIdx), encoding: .ascii) ?? "MetaWear"
                        self.metadata.name = name
                        return true
                    }
                }
                if manufacturerData.count >= 2 {
                    if manufacturerData[0] == Constants.oldMagicByte0 && manufacturerData[1] == Constants.oldMagicByte1 {
                        // Get and update (or create) the metadata
                        let name = String(data: manufacturerData.suffix(from: Constants.oldNameStartingIdx), encoding: .ascii) ?? "MetaWear"
                        self.metadata.name = name
                        return true
                    }
                }
            }
            return false
        }
    }
    
    func updateBatteryValue() {
        guard isConnectedAndSetup, let signal = mbl_mw_settings_get_battery_state_data_signal(board) else {
            return
        }
        signal.read().continueOnSuccessWith {
            let charge = ($0.valueAs() as MblMwBatteryState).charge
            self.metadata.battery = charge
        }
    }
}
