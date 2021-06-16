//
//  WalkthroughTests.swift
//  MetaBaseTests
//
//  Created by Stephen Schiffli on 3/21/18.
//  Copyright © 2018 MBIENTLAB, INC. All rights reserved.
//

import XCTest
import MetaWear
@testable import MetaBase

class WalkthroughTests: XCTestCase {
    var wait: XCTestExpectation!
    let tutorial = Tutorial()
    
    func testExample() {
        wait = expectation(description: "wait")
        tutorial.delegate = self
        tutorial.startWalkthrough()
        waitForExpectations(timeout: 60000, handler: nil)
    }
}

extension WalkthroughTests: TutorialDelegate {
    func updateUI(message: String, icon: UIImage?, buttonText: String?, chart: Bool) {
        print("\(message), \(String(describing: icon)), \(String(describing: buttonText))")
        if buttonText != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.tutorial.buttonTapped()
            }
        }
    }
    
    func newDataPoint(value: CGFloat) {
        print("value")
    }
    
    func tutorialComplete(device: MetaWear?, error: Error?) {
        XCTAssertNil(error)
        wait.fulfill()
    }
}

