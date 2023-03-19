// Copyright © 2023 by MBIENTLAB, Inc. All rights reserved.

import XCTest
@testable import MbientlabUI

final class SFSymbolTests: XCTestCase {

  func testRawValuesResolveToSystemNames() {
    for systemName in SFSymbol.allCases.map(\.rawValue) {
      #if os(macOS)
      let image = NSImage(systemSymbolName: systemName, accessibilityDescription: nil)
      #elseif os(iOS)
      let image = UIImage(systemName: systemName)
      #endif
      XCTAssertNotNil(image, systemName)
    }
  }
}
