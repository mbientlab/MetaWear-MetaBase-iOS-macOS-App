// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import CoreData
import MetaWear

extension NSManagedObjectContext {

    func fetch<M, App>(_ request: NSFetchRequest<M>, result: @escaping (Result<[App],Error>) -> Void) throws
    where M: NSManagedObject, M: ModelConvertible, App == M.ModelType {
        self.perform { [weak self] in
            do {
                let fetched = try self?.fetch(request) ?? []
                let model = try fetched.map { try $0.mapToAppModel() }
                result(.success(model))
            } catch { result(.failure(error)) }
        }
    }
}

protocol ModelConvertible {
    associatedtype ModelType
    func mapToAppModel() throws -> ModelType
}

extension DeviceMO: ModelConvertible {

    func mapToAppModel() throws -> MACAddress {
        guard let mac = mac else { throw CocoaError(.coderInvalidValue) }
        return mac
    }
}

extension FileMO: ModelConvertible {

    func mapToAppModel() throws -> File {
        guard let id = id,
              let name = name,
              let csv = csv
        else { throw CocoaError(.coderInvalidValue) }

        return File(id: id, csv: csv, name: name)
    }
}

extension SessionMO: ModelConvertible {

    func mapToAppModel() throws -> Session {

        guard let date = date,
              let name = name,
              let id = id
        else { throw CocoaError(.coderInvalidValue) }

        return Session(id: id,
                       date: date,
                       name: name,
                       group: group,
                       devices: .init(),
                       files: .init(),
                       didComplete: didComplete
        )
    }
}
