// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation

/// Sensor User Parameters Preset
public struct SUPPreset: Identifiable, Hashable, Equatable {
    public let id: UUID
    public var name: String
    public let parameters: SensorUserParameters

    public init(id: UUID = .init(),
                  name: String,
                  parameters: SensorUserParameters) {
        self.id = id
        self.name = name
        self.parameters = parameters
    }
}

public extension SUPPreset {

    func updated(for newParameters: SensorUserParameters) -> Self {
        .init(id: id, name: name, parameters: newParameters)
    }

    func updated(for newName: String) -> Self {
        .init(id: id, name: newName, parameters: parameters)
    }

    func matchesModules(for legal: LegalSensorParameters) -> Bool {
        if !legal.accelerometer && parameters.accelerometer { return false }
        if !legal.ambientLight && parameters.ambientLight { return false }
        if !legal.barometer && (parameters.pressure || parameters.altitude) { return false }
        if !legal.fusion && parameters.sensorFusion { return false }
        if !legal.gyroscope && parameters.gyroscope { return false }
        if !legal.humidity && parameters.humidity { return false }
        if !legal.magnetometer && parameters.magnetometer { return false }
        if !legal.temperature && parameters.temperature { return false }
        return true
    }
}

public extension Dictionary where Value == SUPPreset {

    func filter(matching legal: LegalSensorParameters) -> [SUPPreset] {
        reduce(into: [SUPPreset]()) { result, element in
            guard element.value.matchesModules(for: legal) else { return }
            result.append(element.value)
        }
        .sorted(by: {
            guard $0.name == $1.name else { return $0.name < $1.name }
            return $0.id < $1.id
        })
    }
}
