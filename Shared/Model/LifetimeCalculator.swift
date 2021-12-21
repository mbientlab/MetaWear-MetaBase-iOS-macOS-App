// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import MetaWear


public struct MWLifetimeCalculator {

    /// Seconds
    var logLife: Double = 0
    /// Seconds
    var batteryLife: Double = 0

    public init(config: UserSensorConfiguration,
                models: [MetaWear.Model],
                modules: [[MWModules]]) {

        let logSize = smallestLogSize(in: models)
        let entriesGeneratedPerSecond = max(0.001, entriesGeneratedPerSecond(for: config))
        let logLifeSeconds = Double(logSize) / entriesGeneratedPerSecond
        self.logLife = roundDownToNearest(logLifeSeconds, minutes: 5)

        let (index, smallestBattery) = smallestBattery(in: models) 
        let powerConsumption = powerConsumptionMilliamperes(for: config, modules: modules[index])
        let batteryLifeHours = Double(smallestBattery) / (max(0.01, powerConsumption))
        let batteryLifeSeconds = batteryLifeHours * 60 * 60 // seconds in hour
        self.batteryLife = roundDownToNearest(batteryLifeSeconds, minutes: 15)
    }

}

// MARK: - Calculations

public extension MWLifetimeCalculator {

    func smallestBattery(in models: [MetaWear.Model]) -> (index: Int, size: Int) {
        var index = 0
        var minSize = Int.max
        for i in models.indices {
            if models[i].batterySize < minSize {
                minSize = models[i].batterySize
                index = i
            }
        }
        return minSize == Int.max ? (index: 0, size: 0) : (index, minSize)
    }

    /// Returns: - Battery life in seconds
    func powerConsumptionMilliamperes(for config: UserSensorConfiguration, modules: [MWModules]) -> Double {
        var mA = Double(0)
        if config.accelerometer {
            let maxAccConsumption = modules.reduce(Double(0)) { result, module in
                guard case .accelerometer = module else { return result }
                return max(module.powerConsumption, result)
            }
            mA += maxAccConsumption
        }
        if config.altitude || config.pressure {
            let maxBaroConsumption = modules.reduce(Double(0)) { result, module in
                guard case .barometer = module else { return result }
                return max(module.powerConsumption, result)
            }
            mA += maxBaroConsumption
        }
        if config.ambientLight { mA += MWModules.illuminance.powerConsumption }
        if config.gyroscope { mA += MWModules.gyroscope(.bmi270).powerConsumption }
        if config.humidity { mA += MWModules.humidity.powerConsumption }
        if config.magnetometer { mA += MWModules.magnetometer.powerConsumption }
        if config.temperature { mA += MWModules.thermometer([]).powerConsumption }
        if config.sensorFusion { mA += MWModules.sensorFusion.powerConsumption }
        return mA
    }

    func smallestLogSize(in models: [MetaWear.Model]) -> Int {
        models.min(by: { $0.logSize < $1.logSize })?.logSize ?? 0
    }

    func entriesGeneratedPerSecond(for config: UserSensorConfiguration) -> Double {
        var entries = Double(0)
        if config.accelerometer { entries += 2 * config.accelerometerRate.freq.rateHz }
        if config.altitude || config.pressure { entries += 1 * config.barometerRate.freq.rateHz }
        if config.ambientLight { entries += 1 * config.ambientLightRate.freq.rateHz }
        if config.gyroscope { entries += 2 * config.gyroscopeRate.freq.rateHz }
        if config.humidity { entries += 1 * config.humidityRate.freq.rateHz }
        if config.magnetometer { entries += 2 * config.magnetometerRate.freq.rateHz }
        if config.temperature { entries += 1 * config.temperatureRate.freq.rateHz }
        if config.sensorFusion {
            switch config.sensorFusionType {
                case .eulerAngles, .quaternion:
                    entries += 4 * MWFrequency.hz100.rateHz
                case .gravity, .linearAcceleration:
                    entries += 3 * MWFrequency.hz100.rateHz
            }
        }
        return entries
    }


    func roundDownToNearest(_ seconds: Double, minutes: Double) -> Double {
        let interval: Double = 60 * minutes
        let rounded = (seconds / interval).rounded(.towardZero)
        return rounded * interval
    }
}

// MARK: - Model Data

public extension MetaWear.Model {

    var logSize: Int {
        switch self {
            case .motionS: return 67108864
            case .motionC: return 1048576
            case .motionR: return 1048576
            case .motionRL: return 1048576
            case .tracker: return 262144
            case .wearC: return 7552
            case .wearCPRO: return 7552
            case .environment: return 7552
            case .detector: return 7552
            case .wearR: return 7552
            case .wearRG: return 7552
            case .wearRPRO: return 7552
            case .health: return 7552
            case .unknown: return 7552
        }
    }

    var batterySize: Int {
        switch self {
            case .motionS: return 100
            case .motionC: return 230
            case .motionR: return 100
            case .motionRL: return 100
            case .tracker: return 600
            case .wearC: return 230
            case .wearCPRO: return 230
            case .environment: return 230
            case .detector: return 230
            case .wearR: return 100
            case .wearRG: return 100
            case .wearRPRO: return 100
            case .health: return 100
            case .unknown: return 100
        }
    }
}

public extension MWModules {

    /// milliAmps
    var powerConsumption: Double {
        switch self {
            case .accelerometer(let model):
                switch model {
                    case .bma255: return 0.13
                    case .bmi160: return 0.18
                    case .bmi270: return 0.21
                }
            case .barometer(let model):
                switch model {
                    case .bme280: return 0.0028
                    case .bmp280: return 0.0034
                }
            case .gyroscope: return 0.5
            case .humidity: return 0.0018
            case .illuminance: return 0.22
            case .magnetometer: return 0.5
            case .sensorFusion: return 0.925
            case .thermometer: return 0.01
            case .mechanicalSwitch: return 0.01
            case .led: return 0
            case .gpio: return 0
            case .iBeacon: return 0
            case .haptic: return 0
            case .i2c: return 0
        }
    }
}
