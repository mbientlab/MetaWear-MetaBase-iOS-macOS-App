// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import Combine

public class SensorUserParametersStore {

    public let parameters: AnyPublisher<Dict<SUPPreset>,Never>
    private let _parameters = CurrentValueSubject<Dict<SUPPreset>,Never>([:])

    private unowned let loader: SensorUserParametersPersistence
    private var loading: AnyCancellable? = nil

    public init(loader: SensorUserParametersPersistence) {
        self.loader = loader
        self.parameters = _parameters.dropFirst().share().eraseToAnyPublisher()
        self.update(from: loader.loaded)
    }

}

public extension SensorUserParametersStore {

    func load() {
        loader.load()
    }

    func presetsMatching(legal: LegalSensorParameters) -> AnyPublisher<[SUPPreset],Never> {
        _parameters
            .filter(matching: legal)
            .eraseToAnyPublisher()
    }

    func addPreset(_ preset: SUPPreset) {
        _parameters.value[preset.id] = preset
    }

    func updatePreset(_ update: SUPPreset) {
        guard _parameters.value.keys.contains(update.id) else { return }
        _parameters.value[update.id] = update
    }

    func removePreset(id: SUPPreset.ID) {
        _parameters.value.removeValue(forKey: id)
    }

}

private extension SensorUserParametersStore {

    func update(from loadable: AnyPublisher<[SUPPreset], Never>) {
        loading = loadable
            .map { $0.dictionary() }
            .sink { [weak self] loaded in
                self?._parameters.send(loaded)
            }
    }

}

public typealias Dict<I:Identifiable> = [I.ID:I]

extension Array where Element: Identifiable {
    /// Creates a dictionary, with identifier collisions prioritizing the latter-most element.
    func dictionary() -> Dictionary<Element.ID,Element> {
        reduce(into: [Element.ID:Element]()) { $0[$1.id] = $1 }
    }
}

extension Publisher where Output == Dict<SUPPreset> {

    /// Outputs name-sorted array of matching presets
    func filter(matching legal: LegalSensorParameters) -> AnyPublisher<[SUPPreset], Failure> {
        map { $0.filter(matching: legal) }
        .eraseToAnyPublisher()
    }
}
