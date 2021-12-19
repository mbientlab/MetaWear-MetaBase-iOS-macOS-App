// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import Combine

public protocol SensorUserParametersPersistence: AnyObject {
    func load()
    func save(_ parameters: [SUPPreset])
    var loaded: AnyPublisher<[SUPPreset], Never> { get }
}

// MARK: - Implementation

public class SensorUserParametersLoader: SensorUserParametersPersistence {

    public let loaded: AnyPublisher<[SUPPreset], Never>
    private let _loaded = PassthroughSubject<[SUPPreset],Never>()

    public init() {
        self.loaded = _loaded.eraseToAnyPublisher()
    }

    public func load() {

    }

    public func save(_ parameters: [SUPPreset]) {

    }
}

