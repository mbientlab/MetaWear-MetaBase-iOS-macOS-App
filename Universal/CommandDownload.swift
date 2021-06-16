//
//  CommandDownload.swift
//  MetaBase
//
//  Created by Stephen Schiffli on 1/12/18.
//  Copyright © 2018 MBIENTLAB, INC. All rights reserved.
//

import MetaWear
import MetaWearCpp
import BoltsSwift

struct CommandDownload {
    static func attachSignalHandlers(_ device: MetaWear, configs: [SensorConfig]) -> Task<[State]> {
        guard device.isConnectedAndSetup else {
            return Task<[State]>(error: MetaWearError.operationFailed(message: "device not connected"))
        }
        return Task<Void>(()).continueWithTask(device.apiAccessExecutor) { _ in
            device.updateBatteryValue()
            return device.createAnonymousDatasignals().continueOnSuccessWith(device.apiAccessExecutor) { signals in
                var states: [State] = []
                signals.forEach {
                    let cString = mbl_mw_anonymous_datasignal_get_identifier($0)!
                    let identifier = String(cString: cString)
                    if let config = configs.first(where: { $0.isConfigForAnonymousEventName(identifier) }) {
                        let state = State(sensor: config, device: device, isStreaming: false)
                        states.append(state)
                        mbl_mw_anonymous_datasignal_subscribe($0, bridgeRetained(obj: state), state.handler)
                    }
                }
                return states
            }
        }
    }
}
