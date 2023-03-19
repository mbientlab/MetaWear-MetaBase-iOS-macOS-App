// Copyright © 2023 by MBIENTLAB, Inc. All rights reserved.

import XCTest
@testable import Mocks

final class UUIDIntegerMocksTests: XCTestCase {

  func testShortInput() {
      let output = UUID.mock(id: 9).uuidString
      XCTAssertEqual(output, "90000000-0000-0000-0000-000000000000")
  }

  func testLongestInput() {
      let output = UUID.mock(id: .max).uuidString
      XCTAssertEqual(output, "18446744-0737-0955-1615-000000000000")
  }
}
