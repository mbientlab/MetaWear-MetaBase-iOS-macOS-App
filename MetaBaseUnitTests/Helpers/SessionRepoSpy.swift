// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import Combine
@testable import MetaBase
import MetaWear
import MetaWearSync

class SessionsRepoSpy: SessionRepository {

    init() { }

    var mockFiles: [Session.ID:[File]] = [:]
    var mockSessions: CurrentValueSubject<[Session],Never> = .init([])
    var addedSessions: [(session: Session, files: [File])] = []
    var deletedSessions: [Session] = []

    func fetchAllSessions() -> AnyPublisher<[Session], Error> {
        Just(mockSessions.value).erase()
    }

    func fetchSessions(matchingGroupID: MetaWear.Group.ID) -> AnyPublisher<[Session], Error> {
        Just(mockSessions.value.filter { $0.group == matchingGroupID }).erase()
    }

    func fetchSessions(matchingMAC: MACAddress) -> AnyPublisher<[Session], Error> {
        Just(mockSessions.value.filter { $0.devices.contains(matchingMAC) }).erase()
    }

    func fetchFiles(in session: Session) -> AnyPublisher<[File], Error> {
        let result = mockFiles[session.id, default: []]
        return Just(result).erase()
    }

    func deleteSession(_ session: Session) -> AnyPublisher<Session, Error> {
        mockSessions.value.removeAll(where: { $0.id == session.id })
        return Just(session).erase()
    }

    func renameSession(_ session: Session, newName: String) -> AnyPublisher<String, Error> {
        guard let index = mockSessions.value.firstIndex(of: session)
        else { return Fail(outputType: String.self, failure: CocoaError(.coreData)).eraseToAnyPublisher() }
        mockSessions.value[index].name = newName
        return Just(newName).erase()
    }

    func addSession(_ session: Session, files: [File]) -> AnyPublisher<Session, Error> {
        addedSessions.append((session, files))
        return Just(session).erase()
    }

    var sessionsDidChange: AnyPublisher<Void, Never> { mockSessions.map { _ in () }.eraseToAnyPublisher() }

}

extension Just {
    func erase() -> AnyPublisher<Output,Error> {
        self.setFailureType(to: Error.self).eraseToAnyPublisher()
    }
}
