// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import CoreData
import Combine
import MetaWear
import MetaWearSync

public class CoreDataSessionRepository {

    public let sessionsDidChange: AnyPublisher<Void,Never>
    private unowned let coreData: CoreDataBackgroundController

    public init(coreData: CoreDataBackgroundController) {
        self.coreData = coreData
        self.sessionsDidChange = coreData.containerDidChange.eraseToAnyPublisher()
    }
}

// MARK: - API

extension CoreDataSessionRepository: SessionRepository {

    public func fetchSession(sessionID: Session.ID) -> AnyPublisher<Session, Error> {
        _fetchSession(sessionID: sessionID)
            .tryMap { try $0.session.mapToAppModel() }
            .eraseToAnyPublisher()
    }

    public func fetchAllSessions() -> AnyPublisher<[Session],Error> {
        fetchSessions(withPredicate: { nil })
    }

    public func fetchSessions(matchingGroupID: MetaWearGroup.ID) -> AnyPublisher<[Session],Error> {
        fetchSessions {
            NSPredicate(format: "%K == %@", #keyPath(SessionMO.group), matchingGroupID as CVarArg)
        }
    }

    public func fetchSessions(matchingMAC: MACAddress) -> AnyPublisher<[Session],Error> {
        fetchSessions {
            NSPredicate(format:"ANY devices.mac == %@", matchingMAC)
        }
    }

    public func fetchFiles(sessionID: Session.ID) -> AnyPublisher<[File],Error> {
        _fetchSession(sessionID: sessionID)
            .tryMap { sessionMO, context -> [File] in
                var files = [File]()
                for fault in (sessionMO.files ?? [])  {
                    let fileMO = (fault as! FileMO)
                    let file = try fileMO.mapToAppModel()
                    files.append(file)
                }
                return files
            }
            .eraseToAnyPublisher()
    }

    public func deleteSession(_ session: Session) -> AnyPublisher<Session,Error> {
        _fetchSession(sessionID: session.id)
            .tryMap { sessionMO, context -> Session in
                context.delete(sessionMO)
                try context.save()
                return session
            }
            .eraseToAnyPublisher()
    }

    public func renameSession(_ session: Session, newName: String) -> AnyPublisher<String,Error> {
        _fetchSession(sessionID: session.id)
            .tryMap { sessionMO, context in
                sessionMO.name = newName
                try context.save()
                return sessionMO.name ?? newName
            }
            .eraseToAnyPublisher()
    }

    /// Add or update session
    public func addSession(_ session: Session, files: [File]) -> AnyPublisher<Session,Error> {
        // Grab relevant MetaWear entities
        fetchDevices(deviceIDs: Array(session.devices))
        // Grab relevant prior session or instantiate a new one
            .tryMap { deviceMOs, context -> ([DeviceMO], NSManagedObjectContext, SessionMO) in

                // Populate or update session
                let request = SessionMO.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", session.id as CVarArg)
                let sessionMO = try context.fetch(request).first ?? SessionMO(context: context)
                sessionMO.id = session.id
                sessionMO.name = session.name
                sessionMO.group = session.group
                sessionMO.date = session.date
                sessionMO.didComplete = session.didComplete

                // Populate or update devices
                var devices = deviceMOs
                let existingDeviceMACs = Set(deviceMOs.compactMap(\.mac))
                for deviceMAC in session.devices {
                    guard existingDeviceMACs.contains(deviceMAC) == false else { continue }
                    let newDevice = DeviceMO(context: context)
                    newDevice.mac = deviceMAC
                    devices.append(newDevice)
                }

                devices.forEach {
                    $0.addToSession(sessionMO)
                    sessionMO.addToDevices($0)
                }

                return (deviceMOs, context, sessionMO)
            }
        // Setup files by triggering faults in prior session and/or creating new files
            .tryMap { deviceMOs, context, sessionMO -> ([DeviceMO], NSManagedObjectContext, SessionMO, [FileMO]) in
                var fileMOs = (sessionMO.files ?? []).map { $0 as! FileMO }
                for file in files {
                    guard let fileMO = fileMOs.first(where: { $0.name == file.name }) else {
                        let newFile = FileMO(context: context)
                        newFile.id = file.id
                        newFile.csv = file.csv
                        newFile.name = file.name
                        newFile.session = sessionMO
                        fileMOs.append(newFile)
                        continue
                    }
                    fileMO.csv = file.csv
                }
                fileMOs.forEach { sessionMO.addToFiles($0) }
                return (deviceMOs, context, sessionMO, fileMOs)
            }
            .tryMap { _, context, sessionMO, _ in
                try context.save()
                return try sessionMO.mapToAppModel()
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Core Data Convenience Fetches

private extension CoreDataSessionRepository {

    func fetchDevices(deviceIDs: [MACAddress])
    -> AnyPublisher<(devices: [DeviceMO], context: NSManagedObjectContext),Error> {
        CoreData { weakSelf, context, promise in
            let request = DeviceMO.fetchRequest()

            let predicate = NSPredicate(format: "mac IN %@", deviceIDs)
            request.predicate = predicate

            let result = try context.fetch(request)
            promise(.success((result, context)))
        }
    }

    func fetchDevice(deviceID: MACAddress)
    -> AnyPublisher<(devices: DeviceMO, context: NSManagedObjectContext),Error> {
        CoreData { weakSelf, context, promise in
            let request = DeviceMO.fetchRequest()
            let predicate = NSPredicate(format: "mac == %@", deviceID)
            request.predicate = predicate
            let results = try context.fetch(request)
            guard let result = results.first else {
                promise(.failure(CloudKitCoreDataError.notFound))
                return
            }
            promise(.success((result, context)))
        }
    }

    func _fetchSession(sessionID: Session.ID)
    -> AnyPublisher<(session: SessionMO, context: NSManagedObjectContext),Error> {

        CoreData { weakSelf, context, promise in
            let request = SessionMO.fetchRequest()

            let predicate = NSPredicate(format: "id == %@", sessionID as CVarArg)
            request.predicate = predicate

            guard let result = try context.fetch(request).first else {
                promise(.failure(CloudKitCoreDataError.notFound))
                return
            }
            promise(.success((result, context)))
        }
    }

    func fetchSessionOnMain(sessionID: Session.ID)
    -> AnyPublisher<(session: SessionMO, context: NSManagedObjectContext),Error> {

        CoreDataMain { weakSelf, context, promise in
            let request = SessionMO.fetchRequest()

            let predicate = NSPredicate(format: "id == %@", sessionID as CVarArg)
            request.predicate = predicate

            guard let result = try context.fetch(request).first else {
                promise(.failure(CloudKitCoreDataError.notFound))
                return
            }
            promise(.success((result, context)))
        }
    }

    func fetchSessions(withPredicate: @escaping () -> NSPredicate?) -> AnyPublisher<[Session],Error> {
        CoreData { weakSelf, context, promise in
            let request = SessionMO.fetchRequest()
            let byDate = NSSortDescriptor(keyPath: \SessionMO.date, ascending: false)
            request.sortDescriptors = [byDate]

            if let predicate = withPredicate() {
                request.predicate = predicate
            }

            let results = try context.fetch(request)
            let mapped = try results.map { try $0.mapToAppModel() }
            promise(.success(mapped))
        }
    }
}

// MARK: - CoreData + Combine

private extension CoreDataSessionRepository {

    func CoreData<O>(promise: @escaping CoreDataPromise<O>) -> AnyPublisher<O,Error> {
        Deferred {
            Future { [weak self] future in
                if let context = self?.coreData.makeBackgroundContext() {
                    context.perform {
                        do { try promise(self, context, future) }
                        catch { future(.failure(error)) }
                    }
                }
            }
        }.eraseToAnyPublisher()
    }

    func CoreDataMain<O>(promise: @escaping CoreDataPromise<O>) -> AnyPublisher<O,Error> {
        Deferred {
            Future { [weak self] future in
                if let context = self?.coreData.viewContext {
                    context.perform {
                        do { try promise(self, context, future) }
                        catch { future(.failure(error)) }
                    }
                }
            }
        }.eraseToAnyPublisher()
    }

    typealias CoreDataPromise<O> = (CoreDataSessionRepository?, NSManagedObjectContext, Promise<O,Error>) throws -> Void
    typealias Promise<O,F:Error> = (Result<O,F>) -> Void

}

enum CloudKitCoreDataError: Error {
    case unknown
    case notFound
}

