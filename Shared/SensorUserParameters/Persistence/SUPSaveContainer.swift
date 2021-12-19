// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import MetaWear
import MetaWearSync
import SwiftUI

public struct MBSensorUserParametersSaveContainer: Codable {
    public var versionSentinel = 1
    public let data: Data

    public init(parameters: [SUPPreset], encoder: JSONEncoder = .init()) throws {
        let dto = parameters.map(MBSUPPresetDTO1.init)
        self.data = try encoder.encode(dto)
    }

    public init(data: Data, decoder: JSONDecoder) throws {
        self = try decoder.decode(MBSensorUserParametersSaveContainer.self, from: data)
    }

    public func load(_ decoder: JSONDecoder = .init()) throws -> [SUPPreset] {
        try decoder
            .decode([MBSUPPresetDTO1].self, from: data)
            .map { $0.load() }
    }
}

// MARK: - DTOs

fileprivate struct MBSUPPresetDTO1: Codable {
    let id: UUID
    let name: String
    let parameters: MBSensorUserParametersDTO1

    init(model: SUPPreset) {
        self.id = model.id
        self.name = model.name
        self.parameters = .init(model: model.parameters)
    }

    func load() -> SUPPreset {
        .init(id: id, name: name, parameters: parameters.load())
    }
}

fileprivate struct MBSensorUserParametersDTO1: Codable {

    var accelerometer:   Bool
    var altitude:        Bool
    var ambientLight:    Bool
    var gyroscope:       Bool
    var humidity:        Bool
    var magnetometer:    Bool
    var pressure:        Bool
    var temperature:     Bool
    var sensorFusion:    Bool

    var accelerometerRate: Float
    var ambientLightRate:  Int
    var barometerRate:     Double
    var fusionRate:        Float
    var gyroscopeRate:     Int
    var humidityRate:      String
    var magnetometerRate:  Int
    var temperatureRate:   String

    var accelerometerScale: Int
    var gyroscopeScale:    Int
    var sensorFusionType:   MBSensorFusionOutputTypeDTO1

    init(model: SensorUserParameters) {
        self.accelerometer = model.accelerometer
        self.altitude = model.altitude
        self.ambientLight = model.ambientLight
        self.gyroscope = model.gyroscope
        self.humidity = model.humidity
        self.magnetometer = model.magnetometer
        self.pressure = model.pressure
        self.temperature = model.temperature
        self.sensorFusion = model.sensorFusion

        self.accelerometerRate = model.accelerometerRate.rawValue
        self.ambientLightRate = model.ambientLightRate.rawValue
        self.barometerRate = model.barometerRate.rawValue
        self.fusionRate = model.fusionRate.rawValue
        self.gyroscopeRate = model.gyroscopeRate.rawValue
        self.humidityRate = model.humidityRate.rawValue
        self.magnetometerRate = model.magnetometerRate.rawValue
        self.temperatureRate = model.temperatureRate.rawValue

        self.accelerometerScale = model.accelerometerScale.rawValue
        self.gyroscopeScale = model.gyroscopeScale.rawValue
        self.sensorFusionType = .init(model: model.sensorFusionType)
    }

    func load() -> SensorUserParameters {
        .init(accelerometer: accelerometer,
              altitude: altitude,
              ambientLight: ambientLight,
              gyroscope: gyroscope,
              humidity: humidity,
              magnetometer: magnetometer,
              pressure: pressure,
              temperature: temperature,
              sensorFusion: sensorFusion,
              sensorFusionType: sensorFusionType.model,
              accelerometerRate: .init(rawValue: accelerometerRate) ?? .hz800,
              ambientLightRate: .init(rawValue: ambientLightRate) ?? .ms50,
              barometerRate: .init(rawValue: barometerRate) ?? .ms0_5,
              fusionRate: .init(rawValue: fusionRate) ?? .hz800,
              gyroscopeRate: .init(rawValue: gyroscopeRate) ?? .hz1600,
              humidityRate: .init(rawValue: humidityRate) ?? .hz1,
              magnetometerRate: .init(rawValue: magnetometerRate) ?? .hz30,
              temperatureRate: .init(rawValue: temperatureRate) ?? .hz1,
              accelerometerScale: .init(rawValue: accelerometerScale) ?? .g8,
              gryoscopeScale: .init(rawValue: gyroscopeScale) ?? .dps2000)
    }
}

enum MBSensorFusionOutputTypeDTO1: String, Codable {
    case eulerAngles
    case gravity
    case linearAcceleration
    case quaternion

    init(model: MWSensorFusion.OutputType) {
        switch model {
            case .eulerAngles: self = .eulerAngles
            case .gravity: self = .gravity
            case .linearAcceleration: self = .linearAcceleration
            case .quaternion: self = .quaternion
        }
    }

    var model: MWSensorFusion.OutputType {
        switch self {
            case .eulerAngles: return .eulerAngles
            case .gravity: return .gravity
            case .linearAcceleration: return .linearAcceleration
            case .quaternion: return .quaternion
        }
    }
}
