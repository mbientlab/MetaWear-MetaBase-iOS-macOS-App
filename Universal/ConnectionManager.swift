//
//  ConnectionManager.swift
//  MetaBase
//
//  Created by Stephen Schiffli on 10/18/17.
//  Copyright © 2017 MBIENTLAB, INC. All rights reserved.
//

import CoreBluetooth
import MetaWear
import MetaWearCpp
import iOSDFULibrary
import BoltsSwift


protocol ConnectionManagerDelegate: class {
    func didConnect(_ device: MetaWear, disconnectTask: Task<MetaWear>?, error: Error?)
    func deviceRequestingFirmwareUpdate(_ device: MetaWear, required: Bool, version: String?, performUpdate: @escaping (Bool) -> Void)
    func deviceFirmwareUpdateStarted(_ device: MetaWear)
    func deviceFirmwareUpdateProgress(_ device: MetaWear, progress: Float)
    func deviceFirmwareUpdateComplete(_ device: MetaWear, error: Error?)
}

class ConnectionManager {
    let device: MetaWear!
    weak var delegate: ConnectionManagerDelegate?
    
    var initiator: DFUServiceInitiator?
    var dfuController: DFUServiceController?
    var dfuSource: TaskCompletionSource<Void>?
    
    init(_ device: MetaWear, delegate: ConnectionManagerDelegate) {
        self.device = device
        self.delegate = delegate
    }
    
    func disconnectDevice() {
        device.cancelConnection()
    }
    
    func connectDevice(checkForUpdate: Bool) {
        device.connectAndSetup().continueWith { t in
            // If we cancelled this connection then do nothing
            guard !t.cancelled else {
                return
            }
            let disconnectTask = t.result
            // Forward errors
            guard t.error == nil else {
                self.delegate?.didConnect(self.device, disconnectTask: disconnectTask, error: t.error!)
                return
            }
            guard checkForUpdate && !self.device.isMetaBoot else {
                self.delegate?.didConnect(self.device, disconnectTask: disconnectTask, error: nil)
                return
            }
            self.device.checkForFirmwareUpdate().continueWith { t in
                // Update if avaliable, but just ignore errors (i.e. our website is down)
                guard t.error == nil else {
                    self.delegate?.didConnect(self.device, disconnectTask: disconnectTask, error: nil)
                    return
                }
                // If no result then we are on the latest firmware
                guard let build = t.result ?? nil else {
                    self.delegate?.didConnect(self.device, disconnectTask: disconnectTask, error: nil)
                    return
                }
                self.delegate?.deviceRequestingFirmwareUpdate(self.device, required: false, version: t.result??.firmwareRev) { doUpdate in
                    //if doUpdate {
                        //self.updateFirmware(build)
                    //} else {
                        self.delegate?.didConnect(self.device, disconnectTask: disconnectTask, error: nil)
                    //}
                }
                return
            }
        }
    }
     
    func updateFirmware(_ build: FirmwareBuild? = nil) {
        delegate?.deviceFirmwareUpdateStarted(self.device)
        device.updateFirmware(delegate: self, build: build).continueWith(.mainThread) { t in
            if t.faulted {
                self.delegate?.didConnect(self.device, disconnectTask: nil, error: t.error ?? MetaWearError.operationFailed(message: "DFU failed, try again"))
            } else {
                self.delegate?.deviceFirmwareUpdateComplete(self.device, error: nil)
            }
        }
    }
}

extension ConnectionManager: DFUProgressDelegate {
    func dfuProgressDidChange(for part: Int, outOf totalParts: Int, to progress: Int,
                              currentSpeedBytesPerSecond: Double, avgSpeedBytesPerSecond: Double) {
        delegate?.deviceFirmwareUpdateProgress(device, progress: Float(progress) / 100.0)
    }
}

