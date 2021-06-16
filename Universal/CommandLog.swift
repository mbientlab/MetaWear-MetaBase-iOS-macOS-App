//
//  CommandLog.swift
//  Refactor
//
//  Created by Stephen Schiffli on 1/3/18.
//  Copyright © 2018 MBIENTLAB, INC. All rights reserved.
//

import MetaWear
import MetaWearCpp
import BoltsSwift


struct CommandLog {
    static func start(_ device: MetaWear, configs: [SensorConfig], shipmentId: String? = nil) -> Task<Int32> {
        guard device.isConnectedAndSetup else {
            return Task<Int32>(error: MetaWearError.operationFailed(message: "device not connected"))
        }
        return Task<Void>(()).continueWithTask(device.apiAccessExecutor) { _ in
            device.updateBatteryValue()
            let presentConfigs = configs.filter { $0.exists(device.board) }
            let activeConfigs = presentConfigs.filter { $0.selectedIdx != nil }
            // Make sure we have something to do
            guard !activeConfigs.isEmpty else {
                return Task<Int32>(0)
            }
            // Record everything to startup macro
            mbl_mw_macro_record(device.board, 1)
            // Set loggers for every signal
            let loggingTasks = activeConfigs.map { sensor -> Task<(OpaquePointer, State)> in
                let state = State(sensor: sensor, device: device, isStreaming: false)
                return sensor.signal(device.board, state).continueOnSuccessWithTask(device.apiAccessExecutor) {
                    return $0.datasignalLog()
                }.continueOnSuccessWith {
                    return ($0, state)
                }
            }
            return Task.whenAllResult(loggingTasks).continueOnSuccessWithTask(device.apiAccessExecutor) { results -> Task<()> in
                // Configure every signal
                let configureTasks = results.map { $0.1.sensor.configure(device.board, $0.1) }
                return Task.whenAll(configureTasks)
            }.continueOnSuccessWithTask(device.apiAccessExecutor) { _ -> Task<Int32> in
                // Enable the logging module
                mbl_mw_logging_start(device.board, 0)
                // Start every signal
                activeConfigs.forEach { $0.start(device.board) }
                // Set the fancy scan response
                let response = device.scanResponse(shipmentId: shipmentId)
                mbl_mw_settings_set_scan_response(device.board, [UInt8](response), UInt8(response.count))
                // Setup LED
                mbl_mw_led_stop_and_clear(device.board)
                // Success flash
                var greenPattern = MblMwLedPattern(high_intensity: 31,
                                                   low_intensity: 0,
                                                   rise_time_ms: 100,
                                                   high_time_ms: 200,
                                                   fall_time_ms: 100,
                                                   pulse_duration_ms: 800,
                                                   delay_time_ms: 0,
                                                   repeat_count: 3)
                mbl_mw_led_write_pattern(device.board, &greenPattern, MBL_MW_LED_COLOR_GREEN)
                // Heartbeat flash
                var redPattern = MblMwLedPattern(high_intensity: 10,
                                                 low_intensity: 0,
                                                 rise_time_ms: 100,
                                                 high_time_ms: 200,
                                                 fall_time_ms: 100,
                                                 pulse_duration_ms: 15000,
                                                 delay_time_ms: 2400,
                                                 repeat_count: 0xFF)
                mbl_mw_led_write_pattern(device.board, &redPattern, MBL_MW_LED_COLOR_RED)
                mbl_mw_led_play(device.board)
                
                // Finish off this macro
                return device.macroEndRecord()
            }
        }
    }
}

extension MetaWear {
    func scanResponse(shipmentId: String? = nil) -> Data {
        // Write magic value into scan response to let the world know its
        // logging via the MetaBase app.  This is how we enable "cross platform" support
        // For the tracker we need to shove the 10 character shipmentId before the name
        let payload = ((shipmentId ?? "") + metadata.name).data(using: .ascii) ?? Data()
        var header = Data(bytes: [UInt8(payload.count) + 4, 0xFF, Constants.magicByte0, Constants.magicByte1, Constants.magicByte2])
        header.append(payload)
        return header
    }
}
