// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import MetaWear
import MetaWearSync
import Combine
import mbientSwiftUI

/// Organize legal user intents
public class ConfigureVM: ObservableObject, HeaderVM {

    @Published var shouldStream = true
    @Published var config: UserSensorConfiguration
    @Published var presets: [PresetSensorConfiguration] = []
    public let options: LegalSensorParameters
    public var canStart: Bool { config.totalFreq.rateHz > 0 }
    var selectedPreset: PresetSensorConfiguration? { presets.first(where: { $0.config == config }) }

    public let title: String
    public var deviceCount: Int { devices.endIndex }
    public let showBackButton = true

    private let devices: [MWKnownDevice]
    private let routingItem: Routing.Item
    private unowned let routing: Routing
    private unowned let presetsStore: PresetSensorParametersStore
    private var presetsUpdates: AnyCancellable? = nil

    public init(title: String, item: Routing.Item, devices: [MWKnownDevice], presets: PresetSensorParametersStore, routing: Routing) {
        self.title = title
        self.routingItem = item
        self.devices = devices
        let configuration = UserSensorConfiguration()
        self.config = configuration
        self.options = .init(devices)
        self.presetsStore = presets
        self.routing = routing
        update(presets: presets)
    }
}

// MARK: - Intents: Start

extension ConfigureVM {

    func requestStart() {
        routing.setConfigs(buildConfigContainers())
        routing.setDestination(shouldStream ? .stream : .log)
    }
}

// MARK: - Intents: Toggle Sensor Usage

public extension ConfigureVM {

    func select(preset: PresetSensorConfiguration) {
        self.config = preset.config
    }

    func saveCurrentConfiguration() {
        guard selectedPreset == nil else { return }
        let config = self.config
        getNameInputModally(
            prefilledText: "Untitled",
            primaryLabel: "Save",
            secondaryLabel: "Cancel",
            title: "Save Sensor Configuration",
            message: nil,
            primary: { [weak presetsStore] newName in
                let preset = PresetSensorConfiguration(name: newName, config: config)
                presetsStore?.addPreset(preset)
            }, secondary: { _ in }
        )
    }

    func rename(preset: PresetSensorConfiguration) {
        getNameInputModally(
            prefilledText: preset.name,
            primaryLabel: "Rename",
            secondaryLabel: "Cancel",
            title: "Rename \(preset.name)",
            message: nil,
            primary: { [weak presetsStore] newName in
                presetsStore?.updatePreset(preset.updated(for: newName))
            }, secondary: { _ in }
        )
    }

    func toggleAccelerometer() {
        if config.accelerometer {
            config.disableAccelerometer()
        } else {
            config.enableAccelerometer()
        }
    }

    func toggleAltitude() {
        if config.altitude {
            config.disableAltitude()
        } else {
            config.enableAltitude()
        }
    }

    func toggleGyroscope() {
        if config.gyroscope {
            config.disableGyroscope()
        } else {
            config.enableGyroscope()
        }
    }

    func toggleMagnetometer() {
        if config.magnetometer {
            config.disableMagnetometer()
        } else {
            config.enableMagnetometer()
        }
    }

    func togglePressure() {
        if config.pressure {
            config.disablePressure()
        } else {
            config.enablePressure()
        }
    }

    func toggleFusion() {
        if config.sensorFusion {
            config.disableSensorFusion()
        } else {
            config.enableSensorFusion()
        }
    }

}

// MARK: - Intents: Start Event

private extension ConfigureVM {

    func buildConfigContainers() -> [ModulesConfiguration] {
        devices.map { device in
            ModulesConfiguration(config, modules: device.meta.modules)
        }
    }

    func update(presets: PresetSensorParametersStore) {
        presetsUpdates = presets.parameters.filter(matching: options)
            .sink { [weak self] presets in
                self?.presets = presets
            }
    }
}
