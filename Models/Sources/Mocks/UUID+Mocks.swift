// Copyright © 2023 by MBIENTLAB, Inc. All rights reserved.

#if DEBUG
import Foundation

extension UUID {

  public typealias MockID = UInt64

  public static let mockBlank = UUID.mock(id: 0)

  public static func mock(id: MockID) -> UUID {
    let uuidBase = String(id)
      .padding(
        toLength: UUID.characterLength,
        withPad: "0",
        startingAt: 0
      )

    var substrings = [Substring]()
    var startIndex = uuidBase.startIndex
    for sectionOffset in UUID.sections {
      let endIndex = uuidBase.index(startIndex, offsetBy: sectionOffset)
      substrings.append(uuidBase[startIndex..<endIndex])
      startIndex = endIndex
    }

    let uuidString = substrings.joined(separator: "-")
    return UUID(uuidString: uuidString)!
  }
}

fileprivate extension UUID {
  static let characterLength: Int = Self.sections.reduce(0, +)
  static let sections: [Int] = [8, 4, 4, 4, 12]
}
#endif
