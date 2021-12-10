// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import MetaWear
import Metadata

/// Organize legal user intents
public class SensorConfigurationVM: ObservableObject, HeaderVM {

    @Published var shouldStream = false
    @Published var config: SensorUserParameters
    public let options: LegalSensorParameters
    public var canStart: Bool { config.totalFreq.rateHz > 0 }

    public let title: String
    public var deviceCount: Int { devices.endIndex }
    public let showBackButton = true

    private let devices: [MWKnownDevice]
    private let routingItem: Routing.Item
    private unowned let routing: Routing

    public init(title: String, item: Routing.Item, devices: [MWKnownDevice], routing: Routing) {
        self.title = title
        self.routingItem = item
        self.devices = devices
        let configuration = SensorUserParameters()
        self.config = configuration
        self.options = .init(devices)
        self.routing = routing
    }
}

// MARK: - Intents: Start

extension SensorConfigurationVM {

    func requestStart() {
        let destination: Routing.Destination = shouldStream
        ? .stream(routingItem, buildConfigContainers())
        : .log(routingItem, buildConfigContainers())

        routing.setDestination(destination)
    }
}

// MARK: - Intents: Toggle Sensor Usage

public extension SensorConfigurationVM {

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

private extension SensorConfigurationVM {

     func buildConfigContainers() -> [SensorConfigContainer] {
        devices.map { device in
            SensorConfigContainer(config, modules: device.meta.modules)
        }
    }
}
