// Copyright © 2023 by MBIENTLAB, Inc. All rights reserved.

#if DEBUG
import Foundation
import Models

extension Device.State.LocalUnpairedDevice {

  public static let mockStrongSignal = Self(rssi: -10)
}

extension Device.State.LocalKnownDevice {

  public static let mockStrongSignal = Self(rssi: -10)
}

extension Device.State.RemoteKnownDevice {

  public static let mock = Self()
}

// MARK: - Buildable

extension Device.State.LocalUnpairedDevice: Buildable {

  func setting<Value>(_ targetKeyPath: KeyPath<Self,Value>, _ newValue: Value) -> Self {

    func build<PathValue>(_ objectPath: KeyPath<Self, PathValue>) -> PathValue {
      if objectPath == targetKeyPath {
        return newValue as! PathValue
      }
      return self[keyPath: objectPath]
    }

    return Self(
      rssi: build(\.rssi)
    )
  }
}

extension Device.State.LocalKnownDevice: Buildable {

  func setting<Value>(_ targetKeyPath: KeyPath<Self,Value>, _ newValue: Value) -> Self {

    func build<PathValue>(_ objectPath: KeyPath<Self, PathValue>) -> PathValue {
      if objectPath == targetKeyPath {
        return newValue as! PathValue
      }
      return self[keyPath: objectPath]
    }

    return Self(
      rssi: build(\.rssi)
    )
  }
}

extension Device.State.RemoteKnownDevice: Buildable {

  func setting<Value>(_ targetKeyPath: KeyPath<Self,Value>, _ newValue: Value) -> Self {

    func build<PathValue>(_ objectPath: KeyPath<Self, PathValue>) -> PathValue {
      if objectPath == targetKeyPath {
        return newValue as! PathValue
      }
      return self[keyPath: objectPath]
    }

    return Self()
  }
}
#endif
