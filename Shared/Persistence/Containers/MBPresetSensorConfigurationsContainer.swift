// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import MetaWear
import MetaWearSync
import SwiftUI

/// To save a user's multiple configurations as remembered presets
///
public struct MBPresetSensorConfigurationsContainer: Codable, MWVersioningContainer {
    public typealias Loadable = [PresetSensorConfiguration]
    public var versionSentinel = 1
    private var data: Data = .init()

    public init(data: Data, decoder: JSONDecoder) throws {
        guard data.isEmpty == false else { return }
        self = try decoder.decode(Self.self, from: data)
    }

    public func load(_ decoder: JSONDecoder) throws -> Loadable {
        guard self.data.isEmpty == false else { return .init() }
        return try decoder
            .decode([MBPresetSensorConfigurationDTO1].self, from: data)
            .map { $0.load() }
    }

    public static func encode(_ loadable: Loadable, _ encoder: JSONEncoder) throws -> Data {
        let container = try Self.init(loadable: loadable, encoder: encoder)
        return try encoder.encode(container)
    }

    private init(loadable: Loadable, encoder: JSONEncoder) throws {
        let dto = loadable.map(MBPresetSensorConfigurationDTO1.init)
        self.data = try encoder.encode(dto)
    }
}

/// For one configuration saved for a Session in CoreData, for example
///
public struct MBUserSensorConfigurationContainer: Codable, MWVersioningContainer {
    public typealias Loadable = UserSensorConfiguration
    public var versionSentinel = 1
    private var data: Data = .init()

    public init(data: Data, decoder: JSONDecoder) throws {
        guard data.isEmpty == false else { return }
        self = try decoder.decode(Self.self, from: data)
    }

    public func load(_ decoder: JSONDecoder) throws -> Loadable {
        guard self.data.isEmpty == false else { return .init() }
        return try decoder
            .decode(MBUserSensorConfigurationDTO1.self, from: data)
            .load()
    }

    public static func encode(_ loadable: Loadable, _ encoder: JSONEncoder) throws -> Data {
        let container = try Self.init(loadable: loadable, encoder: encoder)
        return try encoder.encode(container)
    }

    private init(loadable: Loadable, encoder: JSONEncoder) throws {
        let dto = MBUserSensorConfigurationDTO1(model: loadable)
        self.data = try encoder.encode(dto)
    }
}

// MARK: - DTOs

fileprivate struct MBPresetSensorConfigurationDTO1: Codable {
    let id: UUID
    let name: String
    let parameters: MBUserSensorConfigurationDTO1

    init(model: PresetSensorConfiguration) {
        self.id = model.id
        self.name = model.name
        self.parameters = .init(model: model.config)
    }

    func load() -> PresetSensorConfiguration {
        .init(id: id, name: name, config: parameters.load())
    }
}

fileprivate struct MBUserSensorConfigurationDTO1: Codable {

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

    init(model: UserSensorConfiguration) {
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

    func load() -> UserSensorConfiguration {
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

fileprivate enum MBSensorFusionOutputTypeDTO1: String, Codable {
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
