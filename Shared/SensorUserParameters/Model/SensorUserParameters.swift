// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import MetaWear

/// Model User Configurable Parameters
public struct SensorUserParameters: Hashable, Equatable {

    public private(set) var accelerometer   = false
    public private(set) var altitude        = false
    public              var ambientLight    = false
    public private(set) var gyroscope       = false
    public              var humidity        = false
    public private(set) var magnetometer    = false
    public private(set) var pressure        = false
    public              var temperature     = false
    public private(set) var sensorFusion    = false

    public var accelerometerRate:  MWAccelerometer.SampleFrequency = .hz12_5
    public var ambientLightRate:   MWAmbientLight.MeasurementRate  = .ms500
    public var barometerRate:      MWBarometer.StandbyTime         = .ms125
    public var fusionRate:         MWAccelerometer.SampleFrequency = .hz100
    public var gyroscopeRate:      MWGyroscope.Frequency           = .hz25
    public var humidityRate:       MWFrequency.CommonCases         = .every10sec
    public var magnetometerRate:   MWMagnetometer.SampleFrequency  = .hz10
    public var temperatureRate:    MWFrequency.CommonCases         = .hz1

    public var accelerometerScale: MWAccelerometer.GravityRange    = .g16
    public var gyroscopeScale:     MWGyroscope.GraphRange          = .dps2000
    public var sensorFusionType:   MWSensorFusion.OutputType       = .linearAcceleration

    /// Base case of no activity
    public init() { }

}

// MARK: - Frequency Calculation

public extension SensorUserParameters {

    var totalFreq: MWFrequency {
        var freq = MWFrequency(hz: 0)
        if accelerometer { freq += accelerometerRate.freq }
        if altitude || pressure { freq += barometerRate.freq }
        if ambientLight { freq += ambientLightRate.freq }
        if gyroscope { freq += gyroscopeRate.freq }
        if humidity { freq += humidityRate.freq }
        if magnetometer { freq += magnetometerRate.freq }
        if sensorFusion { freq += fusionRate.freq }
        if temperature { freq += temperatureRate.freq }
        return freq
    }

    static let streamableLimit = MWFrequency(hz: 110) // Allow temperature to stream with sensor fusion, for example
    var exceedsStreamableLimit: Bool { totalFreq > Self.streamableLimit }
}

// MARK: - Mutation Rules

public extension SensorUserParameters {

    mutating func enableAltitude() {
        altitude = true
        pressure = false
    }

    mutating func enablePressure() {
        altitude = false
        pressure = true
    }

    mutating func enableAccelerometer() {
        accelerometer = true
        sensorFusion = false
    }

    mutating func enableMagnetometer() {
        magnetometer = true
        sensorFusion = false
    }

    mutating func enableGyroscope() {
        gyroscope = true
        sensorFusion = false
    }

    mutating func enableSensorFusion() {
        accelerometer = false
        magnetometer = false
        gyroscope = false
        sensorFusion = true
    }

    mutating func disableAccelerometer() {
        accelerometer = false
    }

    mutating func disableAltitude() {
        altitude = false
    }

    mutating func disableGyroscope() {
        gyroscope = false
    }

    mutating func disableMagnetometer() {
        magnetometer = false
    }

    mutating func disablePressure() {
        pressure = false
    }

    mutating func disableSensorFusion() {
        sensorFusion = false
    }
}

public extension SensorUserParameters {

    /// Initializer does not validate potentially conflicting parameters.
    init(
        accelerometer: Bool,
        altitude: Bool,
        ambientLight: Bool,
        gyroscope: Bool,
        humidity: Bool,
        magnetometer: Bool,
        pressure: Bool,
        temperature: Bool,
        sensorFusion: Bool,
        sensorFusionType: MWSensorFusion.OutputType,
        accelerometerRate: MWAccelerometer.SampleFrequency,
        ambientLightRate: MWAmbientLight.MeasurementRate,
        barometerRate: MWBarometer.StandbyTime,
        fusionRate: MWAccelerometer.SampleFrequency,
        gyroscopeRate: MWGyroscope.Frequency,
        humidityRate: MWFrequency.CommonCases,
        magnetometerRate: MWMagnetometer.SampleFrequency,
        temperatureRate: MWFrequency.CommonCases,
        accelerometerScale: MWAccelerometer.GravityRange,
        gryoscopeScale: MWGyroscope.GraphRange) {
            self.accelerometer = accelerometer
            self.altitude = altitude
            self.ambientLight = ambientLight
            self.gyroscope = gyroscope
            self.humidity = humidity
            self.magnetometer = magnetometer
            self.pressure = pressure
            self.temperature = temperature
            self.sensorFusion = sensorFusion
            self.sensorFusionType = sensorFusionType
            self.accelerometerRate = accelerometerRate
            self.ambientLightRate = ambientLightRate
            self.barometerRate = barometerRate
            self.fusionRate = fusionRate
            self.gyroscopeRate = gyroscopeRate
            self.humidityRate = humidityRate
            self.magnetometerRate = magnetometerRate
            self.temperatureRate = temperatureRate
            self.accelerometerScale = accelerometerScale
            self.gyroscopeScale = gryoscopeScale
        }
}
