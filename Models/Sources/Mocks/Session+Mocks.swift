// Copyright © 2023 by MBIENTLAB, Inc. All rights reserved.

#if DEBUG
import Foundation
import Models

extension Session {

  public static func blank(id: Session.ID) -> Session {
    Session(
      id: id,
      comments: .init(),
      configuration: .init(),
      date: .init(),
      devices: .init(),
      location: .init(),
      name: .init()
    )
  }

  public static func mockBlank(id: UUID.MockID) -> Session {
    Session.blank(
      id: .mock(id: id)
    )
  }

  public static let mockROM1 = Session
    .mockBlank(id: 1)
    .setting(\.name, "ROM Subject 1")
    .setting(\.date, .distantPast)

  public static let mockROM2 = Session
    .mockBlank(id: 2)
    .setting(\.name, "ROM Subject 2")
    .setting(\.date, .now)

  public static let mockROM3 = Session
    .mockBlank(id: 3)
    .setting(\.name, "ROM Subject 3")
    .setting(\.date, .distantFuture)
}

// MARK: - Buildable

extension Session: Buildable {

  func setting<Value>(_ targetKeyPath: KeyPath<Self,Value>, _ newValue: Value) -> Self {

    func build<PathValue>(_ objectInitPath: KeyPath<Self, PathValue>) -> PathValue {
      if objectInitPath == targetKeyPath {
        return newValue as! PathValue
      }
      return self[keyPath: objectInitPath]
    }

    return Self(
      id: build(\.id),
      comments: build(\.comments),
      configuration: build(\.configuration),
      date: build(\.date),
      devices: build(\.devices),
      location: build(\.location),
      name: build(\.name)
    )
  }
}

// MARK: - Buildable

extension Session: Buildable {

  func setting<Value>(_ targetKeyPath: KeyPath<Self,Value>, _ newValue: Value) -> Self {

    func build<PathValue>(_ objectInitPath: KeyPath<Self, PathValue>) -> PathValue {
      if objectInitPath == targetKeyPath {
        return newValue as! PathValue
      }
      return self[keyPath: objectInitPath]
    }

    return Self(
      id: build(\.id),
      comments: build(\.comments),
      configuration: build(\.configuration),
      date: build(\.date),
      devices: build(\.devices),
      location: build(\.location),
      name: build(\.name)
    )
  }
}
#endif
