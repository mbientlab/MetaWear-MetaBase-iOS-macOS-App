// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import MetaWear
import Metadata

/// Generate sensor configuration based on user parameters
public struct SensorConfigContainer: Equatable, Hashable {

    public var accelerometer: MWAccelerometer? = nil
    public var altitude: MWBarometer.MWAltitude? = nil
    public var ambientLight: MWAmbientLight? = nil
    public var gyroscope: MWGyroscope? = nil
    public var humidity: MWHumidity? = nil
    public var magnetometer: MWMagnetometer? = nil
    public var pressure: MWBarometer.MWPressure? = nil
    public var thermometer: MWThermometer? = nil

    public var fusionEuler: MWSensorFusion.EulerAngles? = nil
    public var fusionGravity: MWSensorFusion.Gravity? = nil
    public var fusionLinear: MWSensorFusion.LinearAcceleration? = nil
    public var fusionQuaternion: MWSensorFusion.Quaternion? = nil

    public init(_ config: SensorUserParameters, modules: [MWModules.ID:MWModules]) {

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
            self.gyroscope = .init(range: config.gyroscopeScale,
                                   frequency: config.gyroscopeRate)
        }

        if config.humidity {
            self.humidity = .init(oversampling: .x1, rate: config.humidityRate.freq)
        }

        if config.magnetometer {
            self.magnetometer = .init(frequency: config.magnetometerRate)
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
            self.thermometer = .init(type: .onboard, channel: onboardChannel, rate: config.temperatureRate.freq)
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

    }

    /// Blank
    public init() {}
}
