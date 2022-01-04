// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Combine
import MetaWear
import MetaWearSync
import mbientSwiftUI

public class HistoricalSessionsVM: ObservableObject {

    // List
    @Published public private(set) var sessions: [Session] = []
    private var sessionsListUpdates = Set<AnyCancellable>()

    // Exports
    @Published private(set) var isDownloading: [Session.ID:Bool] = [:]
    private var exports: [Session.ID:FilesExporter] = [:]
    private var exportQueue: [Session.ID] = []
    private var exportFocus: FilesExporter? = nil
    private var subs = Set<AnyCancellable>()

    // Dependencies
    private unowned let sessionRepo: SessionRepository
    private unowned let routing: Routing
    private unowned let backgroundQueue: DispatchQueue

    public init(sessionRepo: SessionRepository,
                exportQueue: DispatchQueue,
                routing: Routing
    ) {
        self.backgroundQueue = exportQueue
        self.sessionRepo = sessionRepo
        self.routing = routing
    }
}

public extension HistoricalSessionsVM {

    func onAppear() {
        populateSessions()
    }

    /// Enqueues a  download request and presents a move files dialog when the download completes (and any preceding requests have already been handled by the user, one at a  time).
    func download(session: Session) {
        isDownloading[session.id] = true

        if exports.keys.contains(session.id),
           exportQueue.contains(session.id) == false {
            backgroundQueue.async { [weak self] in
                self?.exportQueue.append(session.id)
                self?.showNextExportDialog()
            }
            return
        }

        sessionRepo.fetchFiles(in: session)
            .receive(on: backgroundQueue)
            .tryMap { files -> FilesExporter in
                try FilesExporter(
                    id: session.id,
                    name: session.name,
                    files: files
                )
            }
            .sink { completion in
                switch completion {
                    case .failure(let error): NSLog(error.localizedDescription)
                        DispatchQueue.main.sync { [weak self] in
                            self?.isDownloading[session.id] = false
                        }
                    case .finished: return
                }
            } receiveValue: { [weak self] export in
                self?.exports[session.id] = export
                self?.exportQueue.append(session.id)
                self?.showNextExportDialog()
            }
            .store(in: &subs)
    }

    func rename(session: Session) {
        getNameInputModally(
            prefilledText: session.name,
            primaryLabel: "Rename",
            primaryIsDestructive: false,
            secondaryLabel: "Cancel",
            secondaryIsDestructive: false,
            title: "Rename \(session.name)",
            message: nil,
            primary: { [self] in
                sessionRepo.renameSession(session, newName: $0)
                    .sink { completion in
                        switch completion {
                            case .finished: return
                            case .failure(let error): NSLog(error.localizedDescription)
                        }
                    } receiveValue: { _ in }
                    .store(in: &self.subs)
            },
            secondary: { _ in })
    }

    func delete(session: Session) {
        alert(primaryLabel: "Delete",
              primaryIsDestructive: true,
              secondaryLabel: "Cancel",
              title: "Are you sure you want to delete \(session.name)?",
              message: "Deleted files cannot be recovered.",
              primary: { [self] in

            self.sessionRepo.deleteSession(session)
                .sink { completion in
                    switch completion {
                        case .finished: return
                        case .failure(let error): NSLog(error.localizedDescription)
                    }
                } receiveValue: { _ in }
                .store(in: &subs)

        }, secondary: { })

    }
}

private extension HistoricalSessionsVM {

    ///  Run on background queue. Shows a move dialog
    ///  to copy files from a session to the designated location...
    ///  one at a time.
    ///
    func showNextExportDialog() {
        // Dequeue a set of already downloaded files
        guard exportFocus == nil,
              let sessionID = exportQueue.popLast(),
              let export = exports[sessionID]
        else { return }
        exportFocus = export

        // Present UI and copy files
        export.runExportInteraction(onQueue: backgroundQueue) { [weak self] in

            // Clean up and advance to next queue
            DispatchQueue.main.async { [weak self] in
                self?.isDownloading[sessionID] = false
            }
            self?.exportFocus = nil
            self?.showNextExportDialog()
        }
    }

    // MARK: - Sessions List

    func populateSessions() {
        _fetchSessions()
            .store(in: &sessionsListUpdates)

        sessionRepo.sessionsDidChange
            .sink { [weak self] _ in
                guard let self = self else { return }
                self._fetchSessions()
                    .store(in: &self.sessionsListUpdates)
            }
            .store(in: &sessionsListUpdates)
    }

    func _fetchSessions() -> AnyCancellable {
        let fetch: AnyPublisher<[Session],Error> = {
            switch routing.focus?.item {
                case .known(let mac):
                    return sessionRepo.fetchSessions(matchingMAC: mac)
                case .group(let groupID):
                    return sessionRepo.fetchSessions(matchingGroupID: groupID)
                default: return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
        }()

        return fetch
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                    case .failure(let error): NSLog("\(Self.self)" + error.localizedDescription)
                    case .finished: return
                }
            } receiveValue: { [weak self] sessions in
                self?.sessions = sessions
            }
    }
}
