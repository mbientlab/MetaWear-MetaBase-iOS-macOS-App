//
//  CommandStream.swift
//  Refactor
//
//  Created by Stephen Schiffli on 1/3/18.
//  Copyright © 2018 MBIENTLAB, INC. All rights reserved.
//

import MetaWear
import MetaWearCpp
import BoltsSwift
//import FirebaseAnalytics

struct CommandStream {
    static func start(_ device: MetaWear, configs: [SensorConfig]) -> Task<[State]> {
        guard device.isConnectedAndSetup else {
            return Task<[State]>(error: MetaWearError.operationFailed(message: "device not connected"))
        }
        return Task<Void>(()).continueWithTask(device.apiAccessExecutor) { _ in
            device.updateBatteryValue()
            //Analytics.logEvent("start_stream", parameters: [
            //    "device_name": device.metadata.name,
            //    "mac": device.mac ?? "FF:FF:FF:FF:FF:FF",
            //    "model": device.modelDescription,
            //    "firmware": device.info?.firmwareRevision ?? "N/A"
            //    ])
            let presentConfigs = configs.filter { $0.exists(device.board) }
            let activeConfigs = presentConfigs.filter { $0.selectedIdx != nil }
            let values = activeConfigs.map { config -> (State, Task<()>) in
                let state = State(sensor: config, device: device, isStreaming: true)
                let task = config.signal(device.board, state).continueOnSuccessWithTask(device.apiAccessExecutor) { signal -> Task<OpaquePointer> in
                    return signal.accounterCreateCount()
                }.continueOnSuccessWithTask(device.apiAccessExecutor) { signal -> Task<Void> in
                    mbl_mw_datasignal_subscribe(signal, bridgeRetained(obj: state), state.handler)
                    return config.configure(device.board, state)
                }
                return (state, task)
            }
            return Task.whenAll(values.map { $0.1 }).continueOnSuccessWith(device.apiAccessExecutor) {
                activeConfigs.forEach { $0.start(device.board) }
                return values.map { $0.0 }
            }
        }
    }
    
    static func stop(_ device: MetaWear, state: [State]) -> Task<()> {
        return device.connectAndSetup().continueOnSuccessWithTask(device.apiAccessExecutor) { disconnectTask -> Task<MetaWear> in
            device.updateBatteryValue()
            // Reset after an expected disconnect
            mbl_mw_debug_reset_after_gc(device.board)
            mbl_mw_debug_disconnect(device.board)
            return disconnectTask
        }.continueWith { t in
            // Record the event
            //Analytics.logEvent("stop_stream", parameters: [
            //    "duration": Int(state.oldestTimestamp.timeIntervalSinceNow * -1000.0)
            //    ])
            state.forEach { $0.csv.close() }
            // Copy csv to final location?
            return
        }
    }
}
