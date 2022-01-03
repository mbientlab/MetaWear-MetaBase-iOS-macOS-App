// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import Combine
import MetaWear
import MetaWearSync

public class ActiveLoggingSessionsStore {

    public let tokens: AnyPublisher<Dict<Session.LoggingToken>,Never>
    private let _tokens = CurrentValueSubject<Dict<Session.LoggingToken>,Never>([:])

    private unowned let loader: MWLoader<LoggingTokensLoadable>
    private var loading: AnyCancellable? = nil
    private var saving: AnyCancellable? = nil

    public init(loader: MWLoader<LoggingTokensLoadable>) {
        self.loader = loader
        self.tokens = _tokens.eraseToAnyPublisher()
        self.update(from: loader.loaded)
        save(to: loader)
    }
}

public extension ActiveLoggingSessionsStore {

    func load() throws {
        try loader.load()
    }

    func session(for item: Routing.Item) -> Session.LoggingToken? {
        _tokens.value[item]
    }

    func register(token: Session.LoggingToken) {
        _tokens.value[token.id] = token
    }

    func remove(token: Session.LoggingToken.ID) {
        _tokens.value.removeValue(forKey: token)
    }
}

private extension ActiveLoggingSessionsStore {

    func update(from loadable: AnyPublisher<LoggingTokensLoadable, Never>) {
        loading = loadable
            .map { $0.tokens.dictionary() }
            .sink { [weak self] loaded in
                self?._tokens.send(loaded)
            }
    }

    func save(to loader: MWLoader<LoggingTokensLoadable>) {
        saving = _tokens
            .dropFirst(2) // This store's subject + persistence's first load
            .mapValues()
            .sink {
                do { try loader.save(.init(tokens: $0)) }
                catch {
                    let message = "\(Self.self) \(#function) \(error.localizedDescription)"
                    MWConsoleLogger.shared.logWith(.error, message: message)
                }
            }
    }

}
