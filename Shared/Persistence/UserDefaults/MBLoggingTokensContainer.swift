// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import MetaWear
import MetaWearSync
import mbientSwiftUI

/// To archive a logging session started on one device and later downloaded on another device or after restarting the app
///
public struct MBLoggingTokensContainer: Codable, MWVersioningContainer {
    public typealias Loadable = LoggingTokensLoadable
    public var versionSentinel = 1
    private var data: Data = .init()

    public init(data: Data, decoder: JSONDecoder) throws {
        guard data.isEmpty == false else { return }
        self = try decoder.decode(Self.self, from: data)
    }

    public func load(_ decoder: JSONDecoder) throws -> Loadable {
        guard self.data.isEmpty == false else { return .init() }
        let tokens = try decoder
            .decode([MBLoggingTokenDTO1].self, from: data)
            .map { $0.load() }
        return .init(tokens: tokens)
    }

    public static func encode(_ loadable: Loadable, _ encoder: JSONEncoder) throws -> Data {
        let container = try Self.init(loadable: loadable, encoder: encoder)
        return try encoder.encode(container)
    }

    private init(loadable: Loadable, encoder: JSONEncoder) throws {
        let dto = loadable.tokens.map(MBLoggingTokenDTO1.init)
        self.data = try encoder.encode(dto)
    }
}

// MARK: - DTOs

fileprivate struct MBLoggingTokenDTO1: Codable {
    var id: RoutingItemDTO1
    var date: Date
    var name: String

    init(model: Session.LoggingToken) {
        self.id = .init(model: model.id)
        self.date = model.date
        self.name = model.name
    }

    func load() -> Session.LoggingToken {
        .init(id: id.load(), date: date, name: name)
    }
}

fileprivate enum RoutingItemDTO1: Hashable, Codable {
    case group(UUID)
    case known(MACAddress)

    init(model: Routing.Item) {
        switch model {
            case .group(let id): self = .group(id)
            case .known(let mac): self = .known(mac)
        }
    }

    func load() -> Routing.Item {
        switch self {
            case .group(let id): return .group(id)
            case .known(let mac): return .known(mac)
        }
    }
}
