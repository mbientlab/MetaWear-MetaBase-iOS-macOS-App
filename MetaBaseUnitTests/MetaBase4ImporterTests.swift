// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import XCTest
@testable import MetaBase
import MetaWear
import MetaWearSync
import Combine

class MetaBase4ImporterTests: XCTestCase {

    func test_BundleIncludesCSV() {
        let url = Bundle(for: type(of: self)).url(forResource: "Bart_2022-01-14T15.28.32.189_E2EDDF1A1AA4_Accelerometer", withExtension: "csv")!
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path), url.path)
        XCTAssertNotNil(FileManager.default.contents(atPath: url.path), url.path)
    }

    func test_ObjectGraphInits_DoNotWrite() {
        let sut = TestObjects(setupDefaults: { _ in })
        XCTAssertTrue(sut.defaults.cloudWrites.isEmpty, sut.defaults.cloudWrites.debugDescription)
        XCTAssertTrue(sut.defaults.localContents().isEmpty, sut.defaults.localContents().debugDescription)
    }

    func test_State_FindsDataInLocalDefaults() {
        let test = TestObjects(setupDefaults: TestObjects.addLegacyData)
        let sut = MetaBase4ImportState(test.defaults, localDeviceID: test.deviceID)
        XCTAssertTrue(sut.dataExists)
        XCTAssertTrue(sut.couldImport)
    }

    func test_State_FindsDataInLocalDefaults_RecognizesPreviousImport() {
        let test = TestObjects(markAsImported: true, setupDefaults: TestObjects.addLegacyData)
        let sut = MetaBase4ImportState(test.defaults, localDeviceID: test.deviceID)
        XCTAssertTrue(sut.dataExists)
        XCTAssertFalse(sut.couldImport)
    }

    func test_State_IgnoresFaultyData() {
        let test = TestObjects(setupDefaults: TestObjects.addFaultyLegacyData)
        let sut = MetaBase4ImportState(test.defaults, localDeviceID: test.deviceID)
        XCTAssertFalse(sut.dataExists)
        XCTAssertFalse(sut.couldImport)
    }

    func test_Importer_ParsesAndSavesDataFromMetaBase4() {
        let test = TestObjects(setupDefaults: TestObjects.addLegacyData)
        let sut = test.importer
        var importCount = 0
        let imports = XCTestExpectation()

        var subs = Set<AnyCancellable>()
        sut.importPriorSessions()
            .sink { completion in
                switch completion {
                    case .failure(let error): XCTFail(error.localizedDescription)
                    case .finished: imports.fulfill()
                }
            } receiveValue: { progress in
                importCount = progress
            }
            .store(in: &subs)

        wait(for: [imports], timeout: 5)

        XCTAssertEqual(importCount, 1)
        XCTAssertEqual(test.importer.missingFiles, [])
        XCTAssertEqual(test.importer.couldImportState, false)

        let cloudWrites = test.defaults.cloudWrites
        XCTAssertEqual(test.localDefaultsForImportedDevices(), [test.deviceID])
        XCTAssertEqual(cloudWrites.count, 1)
        XCTAssertEqual(cloudWrites.first?.key, UserDefaults.MetaWear.Keys.importedLegacySessions)
        XCTAssertEqual(cloudWrites.first?.value as? [String], test.localDefaultsForImportedDevices())

        let result = test.sessions.addedSessions
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.session.name, "Legacy Test Session 1")
        XCTAssertEqual(result.first?.session.devices, ["E2:ED:DF:1A:1A:A4"])
        XCTAssertEqual(result.first?.session.files.count, 1)
        XCTAssertEqual(result.first?.session.group, nil)
        XCTAssertEqual(result.first?.session.date.timeIntervalSince1970, bartSingleSessionDate)
    }

    func test_Importer_RejectsRepeatedImportAttempt() {
        let test = TestObjects(setupDefaults: TestObjects.addLegacyData)
        let sut = test.importer
        var importCount = [0, 0]
        let importA = XCTestExpectation()
        let importB = XCTestExpectation()

        var subs = Set<AnyCancellable>()
        sut.importPriorSessions()
            .sink { completion in
                switch completion {
                    case .failure(let error): XCTFail(error.localizedDescription)
                    case .finished: importA.fulfill()
                }
            } receiveValue: { progress in
                importCount[0] = progress
            }
            .store(in: &subs)

        wait(for: [importA], timeout: 5)
        sut.importPriorSessions()
            .sink { completion in
                switch completion {
                    case .failure(let error): XCTAssertEqual(error, .alreadyImportedDataFromThisDevice)
                    case .finished: XCTFail("Must error out")
                }
                importB.fulfill()
            } receiveValue: { progress in
                importCount[1] = progress
                XCTFail("Must error out")
            }
            .store(in: &subs)

        wait(for: [importB], timeout: 5)

        XCTAssertEqual(importCount[0], 1)
        XCTAssertEqual(importCount[1], 0)
        XCTAssertEqual(test.importer.couldImportState, false)
        XCTAssertEqual(test.localDefaultsForImportedDevices(), [test.deviceID])
        XCTAssertEqual(test.defaults.cloudWrites.count, 1)
        XCTAssertEqual(test.sessions.addedSessions.count, 1)
    }

    func test_Importer_RejectsAttemptWithoutValidExistingData() {
        let test = TestObjects(setupDefaults: { _ in })
        let sut = test.importer
        var importCount = 0
        let imports = XCTestExpectation()

        var subs = Set<AnyCancellable>()
        sut.importPriorSessions()
            .sink { completion in
                switch completion {
                    case .failure(let error): XCTAssertEqual(error, .noMetaBase4MetadataToImport)
                    case .finished: XCTFail("Must error out")
                }
                imports.fulfill()
            } receiveValue: { progress in
                importCount = progress
                XCTFail("Must error out")
            }
            .store(in: &subs)

        wait(for: [imports], timeout: 5)

        XCTAssertEqual(importCount, 0)
        XCTAssertEqual(test.importer.couldImportState, false)
        XCTAssertEqual(test.localDefaultsForImportedDevices(), [])
        XCTAssertEqual(test.defaults.cloudWrites.count, 0)
        XCTAssertEqual(test.sessions.addedSessions.count, 0)
    }

    func test_Importer_SkipsCorruptDataInUserDefaults() {
        let test = TestObjects(setupDefaults: { defaults in
            TestObjects.addLegacyData(defaults)
            TestObjects.addFaultyLegacyData(defaults)
        })
        let sut = test.importer
        var importCount = 0
        let imports = XCTestExpectation()

        var subs = Set<AnyCancellable>()
        sut.importPriorSessions()
            .sink { completion in
                switch completion {
                    case .failure(let error): XCTFail(error.localizedDescription)
                    case .finished: imports.fulfill()
                }
            } receiveValue: { progress in
                importCount = progress
            }
            .store(in: &subs)

        wait(for: [imports], timeout: 5)

        XCTAssertEqual(importCount, 1)
        XCTAssertEqual(test.importer.missingFiles, [])
        XCTAssertEqual(test.importer.couldImportState, false)

        let cloudWrites = test.defaults.cloudWrites
        XCTAssertEqual(test.localDefaultsForImportedDevices(), [test.deviceID])
        XCTAssertEqual(cloudWrites.count, 1)
        XCTAssertEqual(cloudWrites.first?.key, UserDefaults.MetaWear.Keys.importedLegacySessions)
        XCTAssertEqual(cloudWrites.first?.value as? [String], test.localDefaultsForImportedDevices())

        let result = test.sessions.addedSessions
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.session.name, "Legacy Test Session 1")
        XCTAssertEqual(result.first?.session.devices, ["E2:ED:DF:1A:1A:A4"])
        XCTAssertEqual(result.first?.session.files.count, 1)
        XCTAssertEqual(result.first?.session.group, nil)
        XCTAssertEqual(result.first?.session.date.timeIntervalSince1970, bartSingleSessionDate)
    }

    func test_Importer_MergesSessions_ToleratingMissingFiles() {
        let test = TestObjects(setupDefaults: { defaults in
            TestObjects.addLegacyData(defaults)
            TestObjects.addTwoSessionsWithMissingFileLegacyData(defaults)
        })
        let sut = test.importer
        var importCount = 0
        let imports = XCTestExpectation()

        var subs = Set<AnyCancellable>()
        sut.importPriorSessions()
            .sink { completion in
                switch completion {
                    case .failure(let error): XCTFail(error.localizedDescription)
                    case .finished: imports.fulfill()
                }
            } receiveValue: { progress in
                importCount = progress
            }
            .store(in: &subs)

        wait(for: [imports], timeout: 5)

        let expectMissingFilesContainsTarget = test.importer.missingFiles.contains(where: {
            $0.contains("Missing.csv")
        })

        XCTAssertEqual(importCount, 2)
        XCTAssertTrue(expectMissingFilesContainsTarget, test.importer.missingFiles.debugDescription)
        XCTAssertEqual(test.importer.couldImportState, false)

        let cloudWrites = test.defaults.cloudWrites
        XCTAssertEqual(test.localDefaultsForImportedDevices(), [test.deviceID])
        XCTAssertEqual(cloudWrites.count, 1)
        XCTAssertEqual(cloudWrites.first?.key, UserDefaults.MetaWear.Keys.importedLegacySessions)
        XCTAssertEqual(cloudWrites.first?.value as? [String], test.localDefaultsForImportedDevices())

        let result = test.sessions.addedSessions.sorted(by: { $0.session.name < $1.session.name })
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result.map(\.session.name), ["Legacy Test Session 1", "Legacy Test Session 2"])
        XCTAssertEqual(result.map(\.session.devices), [Set(["E2:ED:DF:1A:1A:A4", "E2:ED:DF:1A:1A:55"]),
                                                       Set(["E2:ED:DF:1A:1A:A4"])])
        XCTAssertEqual(result.map(\.session.files.count), [2, 0])
        XCTAssertEqual(result.map(\.session.group), [nil, nil])
        XCTAssertEqual(result.map(\.session.date.timeIntervalSince1970), [bartSingleSessionDate, sessionTwoMissingFileDate])
    }
}

extension XCTestExpectation {
    static func inverted() -> XCTestExpectation {
        let x = XCTestExpectation()
        x.isInverted = true
        return x
    }
}

// MARK: - Helpers

fileprivate struct TestObjects {

    init(deviceID: () -> String = Self.randomID,
         markAsImported: Bool = false,
         line: UInt32 = #line,
         setupDefaults: @escaping (DefaultsContainer) -> Void
    ) {
        LegacySessionModel.SensorDataFile.load = { filename in
            let file = filename.dropLast(4)
            guard let url = Bundle(for: MetaBase4ImporterTests.self).url(forResource: String(file), withExtension: "csv")
            else { return nil }
            return FileManager.default.contents(atPath: url.path)
        }

        let id = deviceID()
        let sessions = SessionsRepoSpy()
        let defaults = MockDefaultsContainer(line: line)
        setupDefaults(defaults)
        if markAsImported { Self.markAsImported(defaults, id: id) }
        let loader = MetaWeariCloudSyncLoader(defaults.local, defaults.cloud)
        let store = MetaWearSyncStore(scanner: .shared, loader: loader)
        let importer = MetaBase4SessionDataImporter(sessions: sessions, devices: store, defaults: defaults, localDeviceID: id)

        self.deviceID = id
        self.importer = importer
        self.sessions = sessions
        self.loader = loader
        self.defaults = defaults
        self.store = store
    }

    let backgroundWork: XCTestExpectation = .inverted()
    let deviceID: String
    let sessions: SessionsRepoSpy
    let importer: MetaBase4SessionDataImporter
    let loader: MetaWeariCloudSyncLoader
    let defaults: MockDefaultsContainer
    let store: MetaWearSyncStore

    static func randomID() -> String {
        "TestFake" + String(Int.random(in: Int.min...Int.max))
    }

    static func markAsImported(_ defaults: DefaultsContainer, id: String) {
        let key = UserDefaults.MetaWear.Keys.importedLegacySessions
        var imported = defaults.cloudFirstArray(of: String.self, for: key) ?? []
        imported.append(id)
        defaults.setArray(imported, forKey: key)
    }

    static func addLegacyData(_ defaults: DefaultsContainer) {
        let data = bartSingleSession.data(using: .utf8)
        let key = bartSingleSessionKey
        defaults.local.set(data, forKey: key)
    }

    static func addFaultyLegacyData(_ defaults: DefaultsContainer) {
        let data = faultySingleSession.data(using: .utf8)
        let key = faultySingleSessionKey
        defaults.local.set(data, forKey: key)
    }

    static func addTwoSessionsWithMissingFileLegacyData(_ defaults: DefaultsContainer) {
        let data = twoSessionMissingFileSession.data(using: .utf8)
        let key = twoSessionMissingFileKey
        defaults.local.set(data, forKey: key)
    }

    static func getAsset(named: String, ext: String) -> URL? {
        let bundle = Bundle(for: XCTestCase.self)
        return bundle.url(forResource: named, withExtension: ext, subdirectory: "Assets")
    }

    static let bundleAssets: URL = {
        let bundle = Bundle(for: MetaBase4ImporterTests.self)
        return bundle.resourceURL!.appendingPathComponent("Assets", isDirectory: true)
    }()

    func localDefaultsForImportedDevices() -> [String] {
        let key = UserDefaults.MetaWear.Keys.importedLegacySessions
        return defaults.cloudFirstArray(of: String.self, for: key) ?? []
    }
}

// MARK: - Data

let bartSingleSessionKey = "MetaDataKeyB1E55467-D00A-511F-7148-87A6EB07CBB9"
let bartSingleSession = """
{
  "key": "MetaDataKeyB1E55467-D00A-511F-7148-87A6EB07CBB9",
  "name": "Bart",
  "battery": 100,
  "sessions": [
    {
      "started": 663895712.1889999,
      "note": "Legacy Test Session 1",
      "firmwareRev": "1.7.0",
      "mac": "E2:ED:DF:1A:1A:A4",
      "model": "MetaMotion S",
      "files": [
        {
          "name": "Accelerometer",
          "csvFilename": "Bart_2022-01-14T15.28.32.189_E2EDDF1A1AA4_Accelerometer.csv"
        }
      ],
      "name": "Bart"
    }
  ]
}
"""
let bartSingleSessionDate = TimeInterval(1642202912.189)

let faultySingleSessionKey = "MetaDataKey00000467-D00A-511F-7148-87A6EB07CBB9"
let faultySingleSession = """
{"key":"MetaDataKeyB1E55467-D00A-511F-7148-87A6EB07CBB9","name":"Ba
"""

let twoSessionMissingFileKey = "MetaDataKeyB1E55467-D00A-511F-7148-87A6EB07CBBB"
let twoSessionMissingFileSession = """
{
  "key": "MetaDataKeyB1E55467-D00A-511F-7148-87A6EB07CBBB",
  "name": "Bart",
  "battery": 100,
  "sessions": [
    {
      "started": 663895712.1889999,
      "note": "Legacy Test Session 1",
      "firmwareRev": "1.7.0",
      "mac": "E2:ED:DF:1A:1A:55",
      "model": "MetaMotion S",
      "files": [
        {
          "name": "Accelerometer",
          "csvFilename": "Bart_2022-01-14T15.28.32.189_E2EDDF1A1AA4_Accelerometer.csv"
        }
      ],
      "name": "Bart"
    },
    {
      "started": 663895715.5559999,
      "note": "Legacy Test Session 2",
      "firmwareRev": "1.7.0",
      "mac": "E2:ED:DF:1A:1A:A4",
      "model": "MetaMotion S",
      "files": [
        {
          "name": "Alethiometer",
          "csvFilename": "Missing.csv"
        }
      ],
      "name": "Bart"
    }
  ]
}
"""
let twoSessionsFoundFileDate = bartSingleSessionDate
let sessionTwoMissingFileDate = TimeInterval(1642202915.5559998)
