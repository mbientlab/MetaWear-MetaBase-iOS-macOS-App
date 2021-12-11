// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import MetaWear
import Metadata

/// Validate legal user options for heterogeneous MetaWear groups (or solo device)
public struct LegalSensorParameters {

    /// With mixed Accemerometer BMI and BMA modules,
    /// one MetaWear (BMA) will record slightly faster
    /// than the other(s) due to how Bosch implemented
    /// refresh rates.
    ///
    /// See source of `LegalSensorParameters` and
    /// `MWAccelerometer.SampleFrequency` for
    /// exact implementation details.
    ///
    public let showAccelerometerMixedRateWarning: Bool

    public let accelerometerRate:   [MWAccelerometer.SampleFrequency]
    public let ambientLightRate:    [MWAmbientLight.MeasurementRate]
    public let barometerRate:       [MWBarometer.StandbyTime]
    public let fusionRate:          [MWAccelerometer.SampleFrequency]
    public let gyroscopeRate:       [MWGyroscope.Frequency]
    public let humidityRate:        [MWFrequency.CommonCases]
    public let magnetometerRate:    [MWMagnetometer.SampleFrequency]
    public let temperatureRate:     [MWFrequency.CommonCases]

    public let accelerometerScale:  [MWAccelerometer.GravityRange]
    public let gyroscopeScale:      [MWGyroscope.GraphRange]
    public let sensorFusion:        [MWSensorFusion.OutputType]

    public var accelerometer:       Bool { !accelerometerRate.isEmpty }
    public var ambientLight:        Bool { !ambientLightRate.isEmpty }
    public var barometer:           Bool { !barometerRate.isEmpty }
    public var fusion:              Bool { !fusionRate.isEmpty }
    public var gyroscope:           Bool { !gyroscopeRate.isEmpty }
    public var humidity:            Bool { !humidityRate.isEmpty }
    public var magnetometer:        Bool { !magnetometerRate.isEmpty }
    public var temperature:         Bool { !temperatureRate.isEmpty }

}

public extension LegalSensorParameters {

    init(_ devices: [MWKnownDevice]) {
        self.init(modules: devices.map(\.meta.modules))
    }

    init(modules: Array<[MWModules.ID:MWModules]>) {

        let commonFrequencies = MWFrequency.CommonCases.allCases

        self.ambientLightRate = modules.allSatisfy({ $0.keys.contains(.illuminance) })  ? MWAmbientLight.MeasurementRate.allCases   : []
        self.humidityRate = modules.allSatisfy({ $0.keys.contains(.humidity) })         ? commonFrequencies                         : []
        self.magnetometerRate = modules.allSatisfy({ $0.keys.contains(.magnetometer) }) ? MWMagnetometer.SampleFrequency.allCases   : []
        self.fusionRate = modules.allSatisfy({ $0.keys.contains(.sensorFusion) })       ? MWAccelerometer.SampleFrequency.allCases  : []

        // MARK: - Accelerometers

        let accelerometers = modules.reduce(into: Set<MWAccelerometer.Model>()) { result, dict in
            if let unit = dict[.accelerometer], case MWModules.accelerometer(let model) = unit {
                result.insert(model)
            }
        }
        if accelerometers.isEmpty == false {

            let isMixed = accelerometers.contains(.bma255) && (accelerometers.contains(.bmi160) || accelerometers.contains(.bmi270))
            self.showAccelerometerMixedRateWarning = isMixed

            let soloRates = accelerometers == [.bma255] ? MWAccelerometer.SampleFrequency.bma255 : MWAccelerometer.SampleFrequency.bmi
            self.accelerometerRate = isMixed ? soloRates.filter { $0 != .hz800 } : soloRates

            self.accelerometerScale = accelerometers.contains(.bma255)
            ? MWAccelerometer.GravityRange.allCases.filter { $0 != .g16 }
            : MWAccelerometer.GravityRange.allCases

            self.sensorFusion = MWSensorFusion.OutputType.allCases

        } else {
            self.accelerometerRate = []
            self.accelerometerScale = []
            self.showAccelerometerMixedRateWarning = false
            self.sensorFusion = []
        }

        // MARK: - Barometers

        let barometers = modules.reduce(into: Set<MWBarometer.Model>()) { result, dict in
            if let unit = dict[.barometer], case MWModules.barometer(let model) = unit {
                result.insert(model)
            }
        }
        if barometers.isEmpty == false {
            var barometerRates = Set(MWBarometer.StandbyTime.allCases)
            if barometers.contains(.bme280) {
                barometerRates.formIntersection(Set(MWBarometer.StandbyTime.BMEoptions))
            }
            if barometers.contains(.bmp280) {
                barometerRates.formIntersection(Set(MWBarometer.StandbyTime.BMPoptions))
            }
            self.barometerRate = barometerRates.sorted(by: { $0.rawValue > $1.rawValue })
        } else {
            self.barometerRate = []
        }

        // MARK: - Gyroscopes

        let gyroscopes = modules.reduce(into: Set<MWGyroscope.Model>()) { result, dict in
            if let unit = dict[.gyroscope], case MWModules.gyroscope(let model) = unit {
                result.insert(model)
            }
        }
        self.gyroscopeRate = gyroscopes.isEmpty == false ? MWGyroscope.Frequency.allCases : []
        self.gyroscopeScale = gyroscopes.isEmpty == false ? MWGyroscope.GraphRange.allCases : []

        // MARK: - Thermometer

        let allHaveOnboardThermometer: Bool = {
            for device in modules {
                guard let unit = device[.thermometer] else { return false }
                guard case MWModules.thermometer(let sources) = unit else { return false }
                guard sources.contains(.onboard) else { return false }
            }
            return true
        }()
        self.temperatureRate = allHaveOnboardThermometer ? MWFrequency.CommonCases.allCases : []
    }
}

