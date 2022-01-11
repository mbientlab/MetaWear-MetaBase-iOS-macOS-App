// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import MetaWear
import Combine
import MetaWearSync

public class MetaBase4SessionDataImporter {

    /// Whether an import completed during this or a prior app session. Updated on main queue.
    public private(set) var didImport = false

    public init(
        sessions: SessionRepository,
        devices: MetaWearSyncStore,
        defaults: UserDefaultsContainer,
        workQueue: DispatchQueue = .global(qos: .userInitiated)
    ) {
        self.queue = workQueue
        self.sessions = sessions
        self.devices = devices
        self.defaults = defaults
        self.didImport = self.didImportOnThisDevice()

        if didImport == false { loadGroups() }
    }

    public enum ImportError: Error, LocalizedError, Equatable {
        case noMetaBase4MetadataToImport
        case alreadyImportedDataFromThisDevice
        case unexpected(Error)


        public var errorDescription: String? {
            switch self {
                case .noMetaBase4MetadataToImport: return "No MetaBase 4 session data found. Try importing from another iOS device."
                case .alreadyImportedDataFromThisDevice: return "Already imported MetaBase 4 session data from this device."
                case .unexpected(let error): return error.localizedDescription
            }
        }

        public static func == (lhs: MetaBase4SessionDataImporter.ImportError, rhs: MetaBase4SessionDataImporter.ImportError) -> Bool {
            switch (lhs, rhs) {
                case (.noMetaBase4MetadataToImport, .noMetaBase4MetadataToImport), (.alreadyImportedDataFromThisDevice, .alreadyImportedDataFromThisDevice): return true
                case (.unexpected(let left), .unexpected(let right)):
                    return left.localizedDescription == right.localizedDescription
                default: return false
            }
        }
    }

    // MARK: - Internal properties

    // - Import
    /// Sessions imported thus far
    private let progress: CurrentValueSubject<Int,ImportError> = .init(0)
    /// Outer: Session with unique start date.
    /// Inner: Device-centric session models for that date.
    private var importQueue: [[LegacySessionModel]] = []
    private var importKickoff: AnyCancellable? = nil
    private var importQueueSub: AnyCancellable? = nil
    private var groupsSub: AnyCancellable? = nil
    private let queue: DispatchQueue

    // - Grouped devices in MetaBase 5
    private var didLoadGroups = false
    private let groups: CurrentValueSubject<[Set<MACAddress>:UUID],Never> = .init([:])

    // - Dependencies
    private unowned let sessions: SessionRepository
    private unowned let devices: MetaWearSyncStore
    private unowned let defaults: UserDefaultsContainer
    private let key = UserDefaults.MetaWear.Keys.importedLegacySessions
    private let legacyPrefix = "MetaDataKey"

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
        guard didImport == false else {
            return Fail(error: ImportError.alreadyImportedDataFromThisDevice)
                .eraseToAnyPublisher()
        }

        defer { performImport() }

        // Provide progress updates for import
        return progress.receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }

    /// Wipes UserDefaults (cannot recover) and trashes CSV files (recoverable).
    ///
    func removePriorSessions(didComplete: @escaping (Error?) -> Void) {
        queue.async {

            // Clear local metadata
            UserDefaults.standard.dictionaryRepresentation().forEach { key, _ in
                guard key.hasPrefix(self.legacyPrefix) else { return }
                UserDefaults.standard.removeObject(forKey: key)
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

    /// Whether this machine contains local MetaBase 4 data that can be imported. Expensive to calculate.
    ///
    func legacyDataExists() -> Bool {
        let decoder = JSONDecoder()
        return UserDefaults.standard.dictionaryRepresentation()
            .contains {
                guard $0.key.hasPrefix(legacyPrefix),
                      let data = $0.value as? Data,
                      let metadata = try? decoder.decode(LegacyMetadata.self, from: data),
                      metadata.sessions.isEmpty == false
                else { return false }
                return true
            }
    }
}

// MARK: - Import

private extension MetaBase4SessionDataImporter {

    func performImport() {
        queue.async { [self] in
            let perform = {
                importQueue = groupLegacySessions(in: loadLegacyMetadata())
                guard importQueue.isEmpty == false else {
                    // End early
                    markThisDeviceAsImported()
                    progress.send(completion: .failure(ImportError.noMetaBase4MetadataToImport))
                    return
                }
                importNextSession()
            }

            guard didLoadGroups else {
                // Wait for groups to load, then kickoff import
                importKickoff = groups.sink { _ in perform() }
                return
            }
            perform()
        }
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
            name: representativeItem.name,
            group: groupID,
            devices: deviceMACs,
            files: Set(files.map(\.id))
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
        DispatchQueue.main.async { [self] in
            didImport = true
            var imported = defaults.cloudFirstArray(of: String.self, for: key) ?? []
            imported.append(getUniqueDeviceIdentifier())
            defaults.setArray(imported, forKey: key)
        }
    }

}

// MARK: - Helper Methods

private extension MetaBase4SessionDataImporter {

    func didImportOnThisDevice() -> Bool {
        guard let pastImports = defaults.cloudFirstArray(of: String.self, for: key)
        else { return false }
        let deviceID = getUniqueDeviceIdentifier()
        return pastImports.contains(deviceID)
    }

    /// Obtain all CSVs files available for a legacy session
    ///
    func getLegacyFiles(in deviceSessions: [LegacySessionModel]) -> [File] {
        deviceSessions.reduce(into: [File]()) { output, legacy in
            legacy.files.forEach { legacyFile in
                guard let data = FileManager.default.contents(atPath: legacyFile.url.path) else { return }
                let file = File(id: .init(),
                                csv: data,
                                name: legacyFile.csvFilename)
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
        let keyPrefixLength = legacyPrefix.count
        let decoder = JSONDecoder()

        let devices = UserDefaults.standard.dictionaryRepresentation()
            .reduce(into: [MACAddress:LegacyMetadata]()) { dict, element in
                guard element.key.hasPrefix(legacyPrefix),
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
            .sink { [self] in
                groups.value = $0
                didLoadGroups = true
            }
    }
}

fileprivate extension FileManager {
    func shallowUserDocumentsEnumerator() -> FileManager.DirectoryEnumerator? {
        guard let documentsURL = urls(for: .documentDirectory, in: .userDomainMask).first
        else { return nil }
        return enumerator(at: documentsURL, includingPropertiesForKeys: [], options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants])
    }
}
