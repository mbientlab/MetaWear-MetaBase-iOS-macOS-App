// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import CoreData
import Combine
import MetaWear
import MetaWearSync

public class CoreDataSessionRepository {

    private unowned let coreData: CoreDataBackgroundController

    public init(coreData: CoreDataBackgroundController) {
        self.coreData = coreData
    }
}

// MARK: - API

public extension CoreDataSessionRepository {

    func fetchAllSessions() -> AnyPublisher<[Session],Error> {
        fetchSessions(withPredicate: { nil })
    }

    func fetchSessions(matchingGroupID: MetaWear.Group.ID) -> AnyPublisher<[Session],Error> {
        fetchSessions {
            NSPredicate(format: "group == %@", matchingGroupID as CVarArg)
        }
    }

    func fetchSessions(matchingMAC: MACAddress) -> AnyPublisher<[Session],Error> {
        fetchSessions {
            NSPredicate(format:"ANY devices.mac == %@", matchingMAC)
        }
    }

    func fetchFiles(in session: Session) -> AnyPublisher<[File],Error> {
        CoreData { weakSelf, context, promise in
            let request = FileMO.fetchRequest()

            let predicate = NSPredicate(format: "id IN %@", Array(arrayLiteral: session.files))
            request.predicate = predicate

            let results = try context.fetch(request)
            let mapped = try results.map { try $0.mapToAppModel() }
            promise(.success(mapped))
        }
    }

    func deleteSession(_ session: Session) -> AnyPublisher<Bool,Error> {
        fetchSession(sessionID: session.id)
            .tryMap { sessionMO, context -> Bool in
                context.delete(sessionMO)
                try context.save()
                return true
            }
            .eraseToAnyPublisher()
    }

    func renameSession(_ session: Session, newName: String) -> AnyPublisher<Bool,Error> {
        fetchSession(sessionID: session.id)
            .tryMap { sessionMO, context -> Bool in
                sessionMO.name = newName
                try context.save()
                return true
            }
            .eraseToAnyPublisher()
    }

    func addSession(_ session: Session, files: [File]) -> AnyPublisher<Session,Error> {
        fetchDevices(deviceIDs: Array(session.devices))
            .tryMap { deviceMOs, context -> Session in
                let newSession = SessionMO(context: context)
                newSession.id = session.id
                newSession.name = session.name
                newSession.group = session.group
                newSession.date = session.date

                let files = files.map { file -> FileMO in
                    let newFile = FileMO(context: context)
                    newFile.id = file.id
                    newFile.name = file.name
                    newFile.session = newSession
                    return newFile
                }

                var devices = deviceMOs
                let existingDeviceMACs = Set(deviceMOs.compactMap(\.mac))
                for deviceMAC in session.devices {
                    guard existingDeviceMACs.contains(deviceMAC) == false else { continue }
                    let newDevice = DeviceMO(context: context)
                    newDevice.mac = deviceMAC
                    devices.append(newDevice)
                }

                devices.forEach {
                    $0.addToSession(newSession)
                    newSession.addToDevices($0)
                }
                files.forEach { newSession.addToFiles($0) }

                try context.save()
                return try newSession.mapToAppModel()
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

    func fetchSession(sessionID: Session.ID)
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

    typealias CoreDataPromise<O> = (CoreDataSessionRepository?, NSManagedObjectContext, Promise<O,Error>) throws -> Void
    typealias Promise<O,F:Error> = (Result<O,F>) -> Void

}

enum CloudKitCoreDataError: Error {
    case unknown
    case notFound
}

