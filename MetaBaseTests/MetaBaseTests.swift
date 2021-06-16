//
//  MetaBaseTests.swift
//  MetaBaseTests
//
//  Created by Stephen Schiffli on 10/26/16.
//  Copyright © 2016 MBIENTLAB, INC. All rights reserved.
//

import XCTest
import Parse
import Bolts
@testable import MetaWear
@testable import MetaBase

class MetaBaseTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Nuke the dir
        try? FileManager.default.removeItem(at: Constants.pendingDirectory)
    }
    
    
    func testValidNames() {
        XCTAssertTrue("Hi Bob-Fat_Fun".isValidName)
        XCTAssertTrue("max character test---___---".isValidName)
        
        XCTAssertFalse("max character test---___---_".isValidName)
        XCTAssertFalse("".isValidName)
        XCTAssertFalse("Hi Bob?".isValidName)
        XCTAssertFalse("Hi Bob⚾️".isValidName)
    }
    
    func testMasking() {
        var count: UInt32 = 0
        var prev: UInt32 = 0xff
        var mask: Int64 = 0xff
        var diff = (Int64(count) - Int64(prev)) & mask
        XCTAssertEqual(diff, 1)
        
        prev = 0xffff
        mask = 0xffff
        diff = (Int64(count) - Int64(prev)) & mask
        XCTAssertEqual(diff, 1)

        prev = 0xfff5
        count = 0x0005
        diff = (Int64(count) - Int64(prev)) & mask
        XCTAssertEqual(diff, 16)
    }
    
//    func testPerformanceOfCreatingSession() {
//        let user = try! PFUser.logIn(withUsername: "stephen", password: "stephen")
//        let totalEntries = 250000
//        let captures = [CapturedData.pressureData(count: totalEntries)]
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//            let _ = Session.fromCaptures(captures, user: user)
//        }
//    }
    
    func testWriteData() {
        let device = MetaWear.spoof()
        let _ = device.accelData(count: 250000)
    }
    
    func testConvertToMetaBase() {
        let url = URL(fileURLWithPath: Bundle.main.path(forResource: "Accelerometer250K", ofType: "csv")!)
        let _ = url.asMetaCloudData()
    }
    
    func testConvertToMetaBasePerf() {
        let url = URL(fileURLWithPath: Bundle.main.path(forResource: "Accelerometer50K", ofType: "csv")!)
        measure {
            let _ = url.asMetaCloudData()
        }
    }

    
    func testBigBeast() {
        let wait = expectation(description: "wait")

        let user = try! PFUser.logIn(withUsername: "stephen", password: "stephen")
        let totalEntries = 100000
        let device = MetaWear.spoof()
        let states = [device.accelData(count: totalEntries)]
        let started = states.oldestTimestamp
        let model = SessionModel(device: device, started: started, states: states, note: "Demo")
        let session = Session.from(model: model, user: user)

        let methodStart = Date()
        Parse.setLogLevel(.debug)
        session.saveInBackground { (success, error) in
            print(success, error ?? "N/A");
            let methodFinish = Date()
            let executionTime = methodFinish.timeIntervalSince(methodStart)
            print("Execution time: \(executionTime)")
            if success {
                session.deleteInBackground { (success, error) in
                    wait.fulfill()
                }
            } else {
                wait.fulfill()
            }
        }

        waitForExpectations(timeout: 60000, handler: nil)
    }
    
    func testReadBigBeast() {
        let wait = expectation(description: "wait")
        
        let _ = try! PFUser.logIn(withUsername: "stephen", password: "stephen")
        let query = Session.query()
        query?.findObjectsInBackground(block: { (array, error) in
            (array as? [Session])?.forEach {
                let x = $0.sensors.first!["data"] as! [[AnyObject]]
                if let timestamp = x.first?.first as? Date {
                    print(timestamp)
                }
            }
            wait.fulfill()
        })
        waitForExpectations(timeout: 60000, handler: nil)
    }
    
    func testSignUp() {
        let x = PFUser()
        x.username = "stephen"
        x.password = "stephen"
        try! x.signUp()
    }
}
