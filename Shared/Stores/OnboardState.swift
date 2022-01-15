// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import Combine

public class OnboardState: ObservableObject {

    @Published private(set) var didOnboard: Bool
    @Published private(set) var canMigrate: Bool
    let launches: Int

    private unowned let importer: MetaBase4SessionDataImporter
    private unowned let defaults: UserDefaultsContainer
    private var onboard: AnyCancellable? = nil
    private var migrate: AnyCancellable? = nil

    public init(_ importer: MetaBase4SessionDataImporter, _ defaults: UserDefaultsContainer, _ launches: LocalLaunchCounter) {
        self.didOnboard = defaults.local.didOnboardAppVersion >= CurrentMetaBaseVersion
        self.canMigrate = importer.couldImportState
        self.importer = importer
        self.defaults = defaults
        self.launches = launches.launches
    }

    public func startMonitoring() {
        onboard = defaults.local.publisher(for: \.didOnboardAppVersion)
            .map { $0 >= CurrentMetaBaseVersion }
            .sink { [weak self]  in self?.didOnboard = $0 }

        migrate = importer.couldImport
            .sink { [weak self] in self?.canMigrate = $0 }
    }
}

extension Bool {
    var opposite: Bool { !self }
}
