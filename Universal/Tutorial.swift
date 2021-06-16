//
//  Tutorial.swift
//  MetaBase
//
//  Created by Stephen Schiffli on 3/21/18.
//  Copyright © 2018 MBIENTLAB, INC. All rights reserved.
//

import UIKit
import MetaWear
import MetaWearCpp
import BoltsSwift


protocol TutorialDelegate: class {
    func updateUI(message: String, icon: UIImage?, buttonText: String?, chart: Bool)
    func newDataPoint(value: CGFloat)
    func tutorialComplete(device: MetaWear?, error: Error?)
}

class Tutorial {
    public weak var delegate: TutorialDelegate?
    var device: MetaWear?
    
    public func startWalkthrough() {
        welcomeScreen().continueOnSuccessWithTask {
            return self.scanForNearby()
        }.continueOnSuccessWithTask {
            self.device = $0
            return self.connecting()
        }.continueOnSuccessWithTask {
            return self.connected()
        }.continueOnSuccessWithTask {
            return self.ledImageTap()
        }.continueOnSuccessWithTask {
            return self.pressMechanicalSwitch()
        }.continueOnSuccessWithTask {
            return self.accelStream()
        }.continueOnSuccessWithTask {
            return self.allDone()
        }.continueWith {
            self.device?.cancelConnection()
            self.delegate?.tutorialComplete(device: self.device, error: $0.error)
        }
    }
    
    public func buttonTapped() {
        buttonSource.trySet(result: ())
    }
    
    public func skip() {
        self.device?.cancelConnection()
        self.delegate?.tutorialComplete(device: self.device, error: MetaWearError.operationFailed(message: "Tutorial skipped"))
    }
    
    
    private let nextSource = TaskCompletionSource<Void>()
    private let doneSource = TaskCompletionSource<Void>()
    private var buttonSource = TaskCompletionSource<Void>()
    
    @objc private func nextPressed(_ sender: UIBarButtonItem!) {
        nextSource.trySet(result: ())
    }
    
    @objc private func donePressed(_ sender: UIBarButtonItem!) {
        doneSource.trySet(result: ())
    }
    
    
    func welcomeScreen() -> Task<Void> {
        buttonSource = TaskCompletionSource<Void>()
        delegate?.updateUI(message: "Let’s connect to your MetaSensor.", icon: nil, buttonText: "NEXT", chart: false)
        
        return buttonSource.task
    }
    
    func scanForNearby() -> Task<MetaWear> {
        delegate?.updateUI(message: "Place your MetaSensor here.", icon: #imageLiteral(resourceName: "mmrMmc"), buttonText: nil, chart: false)
        
        let source = TaskCompletionSource<MetaWear>()
        MetaWearScanner.shared.startScan(allowDuplicates: true) {
            guard let rssi = $0.averageRSSI(), rssi > -50 else {
                return
            }
            MetaWearScanner.shared.stopScan()
            source.trySet(result: $0)
        }
        return source.task
    }
    
    func connecting() -> Task<Void> {
        delegate?.updateUI(message: "Connecting to your MetaSensor.", icon: #imageLiteral(resourceName: "dimSignal"), buttonText: nil, chart: false)
        
        return device!.connectAndSetup().continueOnSuccessWith {
            $0.continueWith {
                guard $0.faulted else {
                    return
                }
                self.startWalkthrough()
            }
        }
    }
    
    func connected() -> Task<Void> {
        delegate?.updateUI(message: "Connected to your MetaSensor.", icon: #imageLiteral(resourceName: "signal"), buttonText: nil, chart: false)
        
        return Task<Void>.withDelay(2.0)
    }
    
    func ledImageTap() -> Task<Void> {
        buttonSource = TaskCompletionSource<Void>()
        delegate?.updateUI(message: "Let's blink the LED.", icon: nil, buttonText: "BLINK", chart: false)
        
        return buttonSource.task.continueWithTask(device!.apiAccessExecutor) { _ in
            self.device!.flashLED(color: .green, intensity: 1.0, _repeat: 4)
            return Task<Void>.withDelay(3.2)
        }
    }
    
    func pressMechanicalSwitch() -> Task<Void>  {
        guard let device = device, let board = device.board else {
            return Task<Void>(())
        }
        return Task<Void>(()).continueWithTask(device.apiAccessExecutor) { _ in
            guard mbl_mw_metawearboard_lookup_module(board, MBL_MW_MODULE_SWITCH) != -1,
                let switchSignal = mbl_mw_switch_get_state_data_signal(board) else {
                    return Task<Void>(())
            }
            
            self.delegate?.updateUI(message: "Press the Button on the MetaSensor.", icon: #imageLiteral(resourceName: "buttonMmrMmc"), buttonText: nil, chart: false)
            let source = TaskCompletionSource<Void>()
            mbl_mw_datasignal_subscribe(switchSignal, bridgeRetained(obj: source)) { (context, data) in
                let source: TaskCompletionSource<Void> = bridge(ptr: context!)
                source.trySet(result: ())
            }
            return source.task.continueWith(device.apiAccessExecutor) { _ in
                mbl_mw_datasignal_unsubscribe(switchSignal)
            }
        }
    }
    
    func accelStream() -> Task<Void> {
        guard let device = device, let board = device.board else {
            return Task<Void>(())
        }
        return Task<Void>(()).continueWithTask(device.apiAccessExecutor) { _ in
           guard mbl_mw_metawearboard_lookup_module(board, MBL_MW_MODULE_ACCELEROMETER) != -1,
            let accel = mbl_mw_acc_get_acceleration_data_signal(board) else {
                return Task<Void>(())
            }
        
            self.delegate?.updateUI(message: "Let’s stream sensor data live.\n\nShake your Device.", icon: nil, buttonText: nil, chart: true)
            mbl_mw_acc_set_odr(board, 10.0)
            mbl_mw_acc_set_range(board, 4.0)
            mbl_mw_acc_write_acceleration_config(board)
            mbl_mw_datasignal_subscribe(accel, bridge(obj: self)) { (context, data) in
                let _self: Tutorial = bridge(ptr: context!)
                let point: MblMwCartesianFloat = data!.pointee.valueAs()
                _self.delegate?.newDataPoint(value: CGFloat(point.magnitude))
            }
            mbl_mw_acc_enable_acceleration_sampling(board)
            mbl_mw_acc_start(board)
            return Task<Void>.withDelay(8.0).continueWith(device.apiAccessExecutor) { _ in
                mbl_mw_acc_stop(board)
                mbl_mw_acc_disable_acceleration_sampling(board)
                mbl_mw_datasignal_unsubscribe(accel)
                mbl_mw_debug_disconnect(board)
            }
        }
    }
    
    func allDone() -> Task<Void> {
        buttonSource = TaskCompletionSource<Void>()
        
        delegate?.updateUI(message: "Now you can use your MetaSensor!", icon: nil, buttonText: "DONE", chart: false)
        return buttonSource.task
    }
}

extension MblMwCartesianFloat {
    var magnitude: Float {
        return sqrt(x*x + y*y + z*z)
    }
}
