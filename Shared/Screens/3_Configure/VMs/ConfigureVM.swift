// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import MetaWear
import MetaWearSync
import Combine
import mbientSwiftUI

/// Organize legal user intents
public class ConfigureVM: ObservableObject, HeaderVM {

    // State
    @Published var shouldStream = true // View edits via binding
    @Published var config: UserSensorConfiguration // View edits via binding
    @Published private(set) var presets: [PresetSensorConfiguration] = []
    public let options: LegalSensorParameters
    public var canStart: Bool { config.totalFreq.rateHz > 0 }
    var selectedPreset: PresetSensorConfiguration? { presets.first(where: { $0.config == config }) }
    var frequencyLabel: String {
        config.totalFreq.rateHz == 0 ? "—" : String(int: config.totalFreq.rateHz) + " Hz"
    }

    // User intent
    @Published private(set) var sessionName: String? = nil
    public var sessionNameBinding: Binding<String> {
        Binding(get: { [weak self] in self?.sessionName ?? self?.selectedPreset?.name ?? "New Session" },
                set: { [weak self] newName in
            guard newName.isEmpty == false
            else { self?.sessionName = nil; return }
            self?.sessionName = newName
        })
    }

    // Estimates
    @Published private(set) var batteryLifetime = "—"
    @Published private(set) var logLifetime = "—"
    private let timeFormatter: DateComponentsFormatter = idiom == .iPhone ? .dayHour() : .dayHourMinute()

    // Header
    public let title: String
    public var deviceCount: Int { devices.endIndex }

    // Model
    private let devices: [MWKnownDevice]
    private let models: [MetaWear.Model]
    private let modules: [[MWModules]]

    // Dependencies
    private let routingItem: Routing.Item
    private unowned let routing: Routing
    private unowned let presetsStore: PresetSensorParametersStore
    private var presetsUpdates: AnyCancellable? = nil
    private var lifetimeEstimates: AnyCancellable? = nil

    public init(title: String, item: Routing.Item, devices: [MWKnownDevice], presets: PresetSensorParametersStore, routing: Routing) {
        self.title = title
        self.routingItem = item
        self.devices = devices
        let configuration = UserSensorConfiguration()
        self.config = configuration
        self.options = .init(devices)
        self.presetsStore = presets
        self.routing = routing
        self.modules = devices.map(\.meta.modules.values).map { $0.map { $0 } }
        self.models = devices.map(\.meta.model)
        update(presets: presets)
        updateLifetimeEstimates()
    }
}

// MARK: - Intents: Start

extension ConfigureVM {

    func requestStart() {
        routing.setConfigs(buildConfigContainers(), sessionNickname: sessionNameBinding.wrappedValue)
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

    func updateLifetimeEstimates() {
        lifetimeEstimates = $config.sink { [weak self] newConfig in
            guard let self = self else { return }
            let empty = "—"
            guard newConfig.totalFreq != .zero else {
                self.batteryLifetime = empty
                self.logLifetime = empty
                return
            }
            let lifetime = MWLifetimeCalculator(config: newConfig, models: self.models, modules: self.modules)
            self.batteryLifetime = self.timeFormatter.string(from: lifetime.batteryLife) ?? empty
            self.logLifetime = self.timeFormatter.string(from: lifetime.logLife)  ?? empty
        }
    }

}
