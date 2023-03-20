// Copyright © 2023 by MBIENTLAB, Inc. All rights reserved.

#if DEBUG
import Foundation
import Models

extension Device {

  public static func mock(id: UUID.MockID) -> Device {
    Device(
      id: .mock(id: id),
      isRecording: false,
      name: String(id),
      state: .neverPaired(.init(rssi: -25))
    )
  }

  public static let mockUnpaired = Self.mock(id: 0)
    .setting(\.name, "MetaWear")

  public static let mockAnkleLeft = Self.mock(id: 1)
    .setting(\.name, "Ankle (L)")
    .setting(\.state, .disconnected(.mockStrongSignal))

  public static let mockAnkleRight = Self.mock(id: 2)
    .setting(\.name, "Ankle (R)")
    .setting(\.state, .disconnected(.mockStrongSignal))

  public static let mockWristLeftRecording = Self.mock(id: 3)
    .setting(\.name, "Wrist (L)")
    .setting(\.state, .disconnected(.mockStrongSignal))
    .setting(\.isRecording, true)

  public static let mockWristRightRecording = Self.mock(id: 4)
    .setting(\.name, "Wrist (R)")
    .setting(\.state, .disconnected(.mockStrongSignal))
    .setting(\.isRecording, true)

}

// MARK: - Buildable

extension Device: Buildable {

  func setting<Value>(_ targetKeyPath: KeyPath<Self,Value>, _ newValue: Value) -> Self {

    func build<PathValue>(_ objectPath: KeyPath<Self, PathValue>) -> PathValue {
      if objectPath == targetKeyPath {
        return newValue as! PathValue
      }
      return self[keyPath: objectPath]
    }

    return Self(
      id: build(\.id),
      isRecording: build(\.isRecording),
      name: build(\.name),
      state: build(\.state)
    )
  }
}
#endif
