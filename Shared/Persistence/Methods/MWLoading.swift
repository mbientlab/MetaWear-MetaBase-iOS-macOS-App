// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import Combine

/// Object that implements some persistence strategy with legacy support
///
open class MWLoader<Loadable: ContainerLoadable> {
    public let loaded: AnyPublisher<Loadable, Never>
    public func load() throws { }
    public func save(_ loadable: Loadable) throws { }
    public init(loaded: AnyPublisher<Loadable, Never>) { self.loaded = loaded }
}


/// Generates wrapped Data for a given type so future releases can parse legacy saved data
///
public protocol MWContainer {
    associatedtype Loadable
    init(data: Data, decoder: JSONDecoder) throws
    func load(_ decoder: JSONDecoder) throws -> Loadable
    static func encode(_ loadable: Loadable, _ encoder: JSONEncoder) throws -> Data
}


/// Links a given type to a persistence container
///
public protocol ContainerLoadable {
    associatedtype Container: MWContainer where Container.Loadable == Self
}
