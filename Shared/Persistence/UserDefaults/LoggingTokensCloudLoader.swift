// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import MetaWearSync

public class LoggingTokensCloudLoader: MWCloudKeyValueDataLoader<LoggingTokensLoadable> {

    public init(_ local: UserDefaults,
                _ cloud: NSUbiquitousKeyValueStore) {
        let key = UserDefaults.MetaWear.Keys.loggingTokens
        super.init(key: key, local, cloud)
    }

    internal convenience init(_ defaults: UserDefaultsContainer) {
        self.init(defaults.local, defaults.cloud)
    }
}

public struct LoggingTokensLoadable {
    public var tokens: [Session.LoggingToken]
    public init(tokens: [Session.LoggingToken] = []) {
        self.tokens = tokens
    }
}

extension LoggingTokensLoadable: VersionedContainerLoadable {
    public typealias Container = MBLoggingTokensContainer
}
