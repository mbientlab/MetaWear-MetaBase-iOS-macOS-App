// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import MetaWear
import MetaWearSync

/// Generate sensor configuration based on user parameters
public struct ModulesConfiguration: Equatable, Hashable {

    public private(set) var accelerometer: MWAccelerometer? = nil
    public private(set) var altitude: MWBarometer.MWAltitude? = nil
    public private(set) var ambientLight: MWAmbientLight? = nil
    public private(set) var gyroscope: MWGyroscope? = nil
    public private(set) var humidity: MWHumidity? = nil
    public private(set) var magnetometer: MWMagnetometer? = nil
    public private(set) var pressure: MWBarometer.MWPressure? = nil
    public private(set) var thermometer: MWThermometer? = nil
    public private(set) var button: MWMechanicalButton? = nil

    public private(set) var fusionEuler: MWSensorFusion.EulerAngles? = nil
    public private(set) var fusionGravity: MWSensorFusion.Gravity? = nil
    public private(set) var fusionLinear: MWSensorFusion.LinearAcceleration? = nil
    public private(set) var fusionQuaternion: MWSensorFusion.Quaternion? = nil

    public private(set) var mode: RecordingModes = .log

    public init(_ config: UserSensorConfiguration,
                modules: [MWModules.ID:MWModules],
                mode: RecordingModes
    ) {
        self.mode = mode

        if config.accelerometer {
            self.accelerometer = .init(rate: config.accelerometerRate,
                                       gravity: config.accelerometerScale)
        }

        if config.altitude {
            self.altitude = .init(standby: config.barometerRate,
                                  iir: .off,
                                  oversampling: .standard)
        }

        if config.ambientLight {
            self.ambientLight = .init(gain: .x1,
                                      integrationTime: .ms100,
                                      rate: config.ambientLightRate)
        }

        if config.gyroscope {
            self.gyroscope = .init(rate: config.gyroscopeRate,
                                   range: config.gyroscopeScale)
        }

        if config.humidity {
            self.humidity = .init(oversampling: .x1, rate: config.humidityRate.freq)
        }

        if config.magnetometer {
            self.magnetometer = .init(freq: config.magnetometerRate)
        }

        if config.pressure {
            self.pressure = .init(standby: config.barometerRate,
                                  iir: .off,
                                  oversampling: .standard)
        }

        if config.temperature,
           let sensors = modules[.thermometer],
           case let MWModules.thermometer(sources) = sensors,
           let onboardChannel = sources.firstIndex(of: MWThermometer.Source.onboard) {
            self.thermometer = .init(rate: config.temperatureRate.freq, type: .onboard, channel: onboardChannel)
        }

        if config.sensorFusion {
            let mode: MWSensorFusion.Mode = modules.keys.contains(.magnetometer) ? .ndof : .imuplus
            switch config.sensorFusionType {
                case .linearAcceleration:   self.fusionLinear = .init(mode: mode)
                case .eulerAngles:          self.fusionEuler = .init(mode: mode)
                case .gravity:              self.fusionGravity = .init(mode: mode)
                case .quaternion:           self.fusionQuaternion = .init(mode: mode)
            }
        }

        if config.button || mode == .remote {
            self.button = MWMechanicalButton()
        }
    }

    /// Blank
    public init() {}
}
