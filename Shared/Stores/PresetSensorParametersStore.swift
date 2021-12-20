// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import Combine

public class PresetSensorParametersStore {

    public let parameters: AnyPublisher<Dict<PresetSensorConfiguration>,Never>
    private let _parameters = CurrentValueSubject<Dict<PresetSensorConfiguration>,Never>([:])

    private unowned let loader: MWLoader<[PresetSensorConfiguration]>
    private var loading: AnyCancellable? = nil
    private var saving: AnyCancellable? = nil

    public init(loader: MWLoader<[PresetSensorConfiguration]>) {
        self.loader = loader
        self.parameters = _parameters.eraseToAnyPublisher()
        self.update(from: loader.loaded)
        save(to: loader)
    }
}

public extension PresetSensorParametersStore {

    func load() throws {
        try loader.load()
    }

    func presetsMatching(legal: LegalSensorParameters) -> AnyPublisher<[PresetSensorConfiguration],Never> {
        _parameters
            .filter(matching: legal)
            .eraseToAnyPublisher()
    }

    func addPreset(_ preset: PresetSensorConfiguration) {
        _parameters.value[preset.id] = preset
    }

    func updatePreset(_ update: PresetSensorConfiguration) {
        guard _parameters.value.keys.contains(update.id) else { return }
        _parameters.value[update.id] = update
    }

    func removePreset(id: PresetSensorConfiguration.ID) {
        _parameters.value.removeValue(forKey: id)
    }

}

private extension PresetSensorParametersStore {

    func update(from loadable: AnyPublisher<[PresetSensorConfiguration], Never>) {
        loading = loadable
            .map { $0.dictionary() }
            .sink { [weak self] loaded in
                self?._parameters.send(loaded)
            }
    }

    func save(to loader: MWLoader<[PresetSensorConfiguration]>) {
        saving = _parameters
            .dropFirst(2)
            .mapValues()
            .sink { try? loader.save($0) }
    }

}

public typealias Dict<I:Identifiable> = [I.ID:I]

extension Array where Element: Identifiable {
    /// Creates a dictionary, with identifier collisions prioritizing the latter-most element.
    func dictionary() -> Dictionary<Element.ID,Element> {
        reduce(into: [Element.ID:Element]()) { $0[$1.id] = $1 }
    }
}

extension Publisher where Output == Dict<PresetSensorConfiguration> {

    /// Outputs name-sorted array of matching presets
    func filter(matching legal: LegalSensorParameters) -> AnyPublisher<[PresetSensorConfiguration], Failure> {
        map { $0.filter(matching: legal) }
        .eraseToAnyPublisher()
    }
}

extension Publisher {

    func mapValues<T:Identifiable>() -> AnyPublisher<[T],Failure> where Output == Dictionary<T.ID,T> {
        map { Array($0.values) }.eraseToAnyPublisher()
    }
}
