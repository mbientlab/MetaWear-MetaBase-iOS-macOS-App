// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import CoreData
import Combine
import MetaWear
import MetaWearSync

public protocol SessionRepository: AnyObject {
    func fetchAllSessions() -> AnyPublisher<[Session],Error>
    func fetchSessions(matchingGroupID: MetaWearGroup.ID) -> AnyPublisher<[Session],Error>
    func fetchSessions(matchingMAC: MACAddress) -> AnyPublisher<[Session],Error>
    func fetchFiles(in session: Session) -> AnyPublisher<[File],Error>
    func deleteSession(_ session: Session) -> AnyPublisher<Session,Error>
    func renameSession(_ session: Session, newName: String) -> AnyPublisher<String,Error>
    func addSession(_ session: Session, files: [File]) -> AnyPublisher<Session,Error>

    var sessionsDidChange: AnyPublisher<Void,Never> { get }
}

/// Implementation in CoreDataSessionRepository

