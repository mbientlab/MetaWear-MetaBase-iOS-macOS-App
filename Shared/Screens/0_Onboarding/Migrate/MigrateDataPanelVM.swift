// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import mbientSwiftUI
import Combine

public class MigrateDataPanelVM: ObservableObject {

    @Published public private(set) var error: MetaBase4SessionDataImporter.ImportError? = nil
    @Published public private(set) var canImport = true
    @Published public private(set) var isImporting: State = .notStarted
    @Published public private(set) var sessionsImported = 0

    public var sessionsImportedLabel: String {
        guard sessionsImported > 0 else { return "" }
        return "Imported \(sessionsImported) sessions"
    }
    public var presentError: Binding<Bool> {
        Binding(
            get: { [weak self] in self?.error != nil },
            set: { [weak self] _ in self?.error = nil }
        )
    }

    private var importSub: AnyCancellable? = nil
    private unowned let importer: MetaBase4SessionDataImporter

    public init(importer: MetaBase4SessionDataImporter) {
        self.importer = importer
        self.canImport = importer.couldImport
    }

    public enum State {
        case notStarted
        case importing
        case completed
    }
}

public extension MigrateDataPanelVM {

    func start() {
        isImporting = .importing
        let wall = DispatchWallTime.now() + .milliseconds(500)

        importSub = importer.importPriorSessions()
            .sink { [self] completion in
                self.canImport = false
                DispatchQueue.main.asyncAfter(wallDeadline: wall) {
                    isImporting = .completed
                }
                switch completion {
                    case .finished: return
                    case .failure(let error): self.error = error
                }
            } receiveValue: { count in
                self.sessionsImported = count
            }
    }

}
