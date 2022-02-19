// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import MetaWear
import Combine
import MetaWearSync

public class MetaBase4SessionDataImporter {

    /// Whether an import completed during this or a prior app session and data exists. Updated on main queue.
    public private(set) lazy var couldImport = couldImportSubject.eraseToAnyPublisher()
    public var couldImportState: Bool { couldImportSubject.value }
    public let legacyDataExistsOnDevice: Bool
    public var missingFiles = [String]()

    public init(
        sessions: SessionRepository,
        devices: MetaWearSyncStore,
        defaults: DefaultsContainer,
        workQueue: DispatchQueue = ._makeQueue(named: "importer", qos: .userInitiated),
        localDeviceID: String
    ) {
        self.queue = workQueue
        self.sessions = sessions
        self.devices = devices
        self.defaults = defaults
        let state = MetaBase4ImportState(defaults, localDeviceID: localDeviceID)
        self.legacyDataExistsOnDevice = state.dataExists
        self.couldImportSubject = .init(state.couldImport)
        self.localDeviceID = localDeviceID
    }

    // MARK: - Internal properties

    // - Import
    /// Sessions imported thus far
    private let progress: CurrentValueSubject<Int,ImportError> = .init(0)
    /// Outer: Session with unique start date.
    /// Inner: Device-centric session models for that date.
    private var importQueue: [[LegacySessionModel]] = []
    private let couldImportSubject: CurrentValueSubject<Bool,Never>
    private var importKickoff: AnyCancellable? = nil
    private var importQueueSub: AnyCancellable? = nil
    private var groupsSub: AnyCancellable? = nil
    private let queue: DispatchQueue
    private var hasImportSession = false

    // - Grouped devices in MetaBase 5
    private let groups: CurrentValueSubject<[Set<MACAddress>:UUID],Never> = .init([:])

    // - Dependencies
    private unowned let sessions: SessionRepository
    private unowned let devices: MetaWearSyncStore
    private unowned let defaults: DefaultsContainer
    private static let key = UserDefaults.MetaWear.Keys.importedLegacySessions
    private static let legacyPrefix = LegacyMetadata.defaultsKeyPrefix
    private let localDeviceID: String
}

// MARK: - Public API

public extension MetaBase4SessionDataImporter {

    /// Imports prior MetaBase 4 session data to the current database,
    /// unless already imported on another device (per iCloud-synced
    /// key value storage). Imported device groups prior to calling this method.
    ///
    /// - Returns: Updates on sessions imported thus far, along with
    /// any error, on the main queue.
    ///
    func importPriorSessions() -> AnyPublisher<Int,ImportError> {
        // If already imported, end early
        guard couldImportSubject.value == true else {
            let error = legacyDataExistsOnDevice
            ? ImportError.alreadyImportedDataFromThisDevice
            : .noMetaBase4MetadataToImport
            return Fail(error: error).eraseToAnyPublisher()
        }

        defer {
            if hasImportSession == false {
                hasImportSession = true
                queue.async { [weak self] in
                    self?.performImport()
                }
            }
        }

        // Provide progress updates for import
        return progress.receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }

    /// Wipes UserDefaults (cannot recover) and trashes CSV files (recoverable).
    ///
    func removePriorSessions(didComplete: @escaping (Error?) -> Void) {
        queue.async { [weak self] in

            // Clear local metadata
            self?.defaults.local.dictionaryRepresentation().forEach { key, _ in
                guard key.hasPrefix(Self.legacyPrefix) else { return }
                self?.defaults.local.removeObject(forKey: key)
            }

            var fmError: Error? = nil

            // Remove documents only in iOS, where this folder will not have extraneous files that shouldn't be touched
            #if os(iOS)
            do {
                let fm = FileManager.default
                guard let enumerator = fm.shallowUserDocumentsEnumerator() else { return }

                for case let fileURL as URL in enumerator {
                    guard fileURL.pathExtension == "csv",
                          fileURL.deletingPathExtension().lastPathComponent.components(separatedBy: "_").count == 3 // Matches MB4 pattern
                    else { continue }
                    try fm.trashItem(at: fileURL, resultingItemURL: nil)
                }

            } catch { fmError = error }
            #endif

            DispatchQueue.main.async {
                didComplete(fmError)
            }
        }
    }
}

// MARK: - Import

private extension MetaBase4SessionDataImporter {

    func performImport() {
        importKickoff = groups
            .dropFirst()
            .first()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.importQueue = self.groupLegacySessions(in: self.loadLegacyMetadata())
                guard self.importQueue.isEmpty == false else {
                    // End early
                    self.markThisDeviceAsImported()
                    self.progress.send(completion: .failure(.noMetaBase4MetadataToImport))
                    return
                }
                self.importNextSession()
            }

        self.loadGroups()
    }

    func importNextSession() {
        guard let deviceSessions = importQueue.popLast(),
              let representativeItem = deviceSessions.first
        else {
            // Complete successfully
            markThisDeviceAsImported()
            progress.send(completion: .finished)
            return
        }

        // Get all files for this session
        let files = getLegacyFiles(in: deviceSessions)

        // Link to device(s) / possible group ID
        let deviceMACs = Set(deviceSessions.map(\.mac))
        let groupID = groups.value[deviceMACs]

        let session = Session(
            id: .init(),
            date: representativeItem.started,
            name: representativeItem.note,
            group: groupID,
            devices: deviceMACs,
            files: Set(files.map(\.id)),
            didComplete: true
        )

        importQueueSub = sessions.addSession(session, files: files)
            .receive(on: queue)
            .sink(receiveCompletion: { completion in
                switch completion {
                    case .finished:
                        self.progress.value += 1
                        self.importNextSession()
                    case .failure(let error):
                        self.progress.send(completion: .failure(.unexpected(error)))
                }
            }, receiveValue: { _ in })
    }

    func markThisDeviceAsImported() {
        DispatchQueue.main.sync { [weak self] in
            guard let self = self else { return }
            self.couldImportSubject.send(false)
            var imported = Set(self.defaults.cloudFirstArray(of: String.self, for: Self.key) ?? [])
            imported.insert(self.localDeviceID)
            self.defaults.setArray(imported.sorted(), forKey: Self.key)
        }
    }

}

// MARK: - Helper Methods

private extension MetaBase4SessionDataImporter {

    /// Obtain all CSVs files available for a legacy session
    ///
    func getLegacyFiles(in deviceSessions: [LegacySessionModel]) -> [File] {
        deviceSessions.reduce(into: [File]()) { output, legacy in
            legacy.files.forEach { legacyFile in
                let path = legacyFile.url.path
                guard let data = legacyFile.load() else {
                    missingFiles.append(path)
                    return
                }
                let file = File(id: .init(), csv: data, name: legacyFile.csvFilename)
                output.append(file)
            }
        }
    }


    /// MetaBase 4 stored sessions in fragments for each participant device.
    /// MetaBase 5 stores sessions as one object, referencing device MACs and possibly a group ID.
    /// This groups MetaBase 4 sessions into arrays aligned with a MetaBase 5 session object.
    ///
    func groupLegacySessions(in prior: [MACAddress:LegacyMetadata]) -> [[LegacySessionModel]] {
        prior.reduce(into: [Date:[LegacySessionModel]]()) { result, element in
            for session in element.value.sessions {
                result[session.started, default: [LegacySessionModel]()].append(session)
            }
        }
        .map(\.value)
    }

    /// Load metadata containing a list of sessions and file paths from the local MetaBase 4 UserDefaults key.
    ///
    func loadLegacyMetadata() -> [MACAddress:LegacyMetadata] {
        let keyPrefixLength = Self.legacyPrefix.count
        let decoder = JSONDecoder()

        let devices = defaults.local.dictionaryRepresentation()
            .reduce(into: [MACAddress:LegacyMetadata]()) { dict, element in
                guard element.key.hasPrefix(Self.legacyPrefix),
                      let data = element.value as? Data,
                      let metadata = try? decoder.decode(LegacyMetadata.self, from: data)
                else { return }
                let mac = String(element.key.dropFirst(keyPrefixLength))
                dict[mac] = metadata
            }

        return devices
    }

    /// Get the current list of grouped devices. Sets a flag to allow the session import process to start once this list is loaded. (Without this list, the correct device group IDs wouldn't be available to assign to the import sessions.)
    ///
    func loadGroups() {
        groupsSub = devices.groups.combineLatest(devices.groupsRecoverable)
            .first()
            .receive(on: queue)
            .map { groups, recoverableGroups -> [Set<MACAddress>:UUID] in

                /// Create a dict of past groups that can be matched against MAC
                /// addresses. Any overlap with current groups will be
                /// overwritten in the next step.
                let recovered = recoverableGroups.reduce(into: [Set<MACAddress>:UUID](), { dict, group in
                    dict[group.deviceMACs] = group.id
                })

                /// Create dict of current groups that can be matched against
                /// the prior SDK's session grouping method (Set of MAC addresses).
                return groups.reduce(into: recovered, { dict, group in
                    dict[group.deviceMACs] = group.id
                })
            }
            .sink { [weak self] in self?.groups.value = $0 }
    }
}

fileprivate extension FileManager {
    func shallowUserDocumentsEnumerator() -> FileManager.DirectoryEnumerator? {
        guard let documentsURL = urls(for: .documentDirectory, in: .userDomainMask).first
        else { return nil }
        return enumerator(at: documentsURL, includingPropertiesForKeys: [], options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants])
    }
}
