// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import XCTest
@testable import MetaBase
import MetaWear
import MetaWearSync
import Combine

class MetaBase4ImporterTests: XCTestCase {

    func addLegacyData(_ defaults: DefaultsContainer) {
        let data = Data()
        let key = LegacyMetadata.defaultsKeyPrefix + ""
        defaults.local.set(data, forKey: key)
    }

    func addFaultyLegacyData(_ defaults: DefaultsContainer) {
        let data = Data()
        let key = LegacyMetadata.defaultsKeyPrefix + ""
        defaults.local.set(data, forKey: key)
    }

    func test_FindsDataInUserDefaults() {
        let test = TestObjects(setupDefaults: addLegacyData)
        XCTAssertTrue(test.sut.legacyDataExistedAtLaunch)
    }

    func test_FailsOnCorruptDataInUserDefaults() {
        let test = TestObjects(setupDefaults: addFaultyLegacyData)
        XCTAssertTrue(test.sut.legacyDataExistedAtLaunch)
    }

    func test_SkipsCorruptDataInUserDefaults() {
        let test = TestObjects(setupDefaults: {
            self.addLegacyData($0)
            self.addFaultyLegacyData($0)
        })
        XCTAssertTrue(test.sut.legacyDataExistedAtLaunch)
    }

    func test_RetrievesDataInDefaults() {
        let test = TestObjects()
        var subs = Set<AnyCancellable>()
        let imports = XCTestExpectation()
        test.sut.importPriorSessions()
            .sink { completion in
                switch completion {
                    case .failure(let error): XCTFail(error.localizedDescription)
                    case .finished:
                        imports.fulfill()
                }
            } receiveValue: { importCount in
                XCTAssertEqual(1, importCount)
            }
            .store(in: &subs)
        wait(for: [imports], timeout: 5)
    }

    struct TestObjects {

        init(setupDefaults: @escaping (DefaultsContainer) -> Void) {
            let sessions = SessionsRepoSpy()
            let defaults = MockDefaultsContainer()
            setupDefaults(defaults)
            let loader = MetaWeariCloudSyncLoader(defaults.local, defaults.cloud)
            let store = MetaWearSyncStore(scanner: .shared, loader: loader)
            let sut = MetaBase4SessionDataImporter(sessions: sessions, devices: store, defaults: defaults)

            self.sut = sut
            self.sessions = sessions
            self.loader = loader
            self.defaults = defaults
            self.store = store
        }

        let sessions: SessionsRepoSpy
        let sut: MetaBase4SessionDataImporter
        let loader: MetaWeariCloudSyncLoader
        let defaults: MockDefaultsContainer
        let store: MetaWearSyncStore
    }

}

extension Just {
    func erase() -> AnyPublisher<Output,Error> {
        self.setFailureType(to: Error.self).eraseToAnyPublisher()
    }
}

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

class MockDefaultsContainer: DefaultsContainer {

    func cloudFirstArray<T>(of type: T.Type, for key: String) -> [T]? {
        local.array(forKey: key) as? [T]
    }

    func setArray(_ array: [Any]?, forKey key: String) {
        local.set(array, forKey: key)
    }

    init(file: String = #file) {
        self.cloud = NSUbiquitousKeyValueStore()
        self.local = UserDefaults(suiteName: file)!
        local.removePersistentDomain(forName: file)
    }

    let cloud: NSUbiquitousKeyValueStore
    let local: UserDefaults
}
