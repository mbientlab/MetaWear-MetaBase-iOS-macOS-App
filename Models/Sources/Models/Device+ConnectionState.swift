// Copyright © 2023 by MBIENTLAB, Inc. All rights reserved.

import Foundation

extension Device {

  public enum State: Equatable {
    case neverPaired(LocalUnpairedDevice)
    case notNearby(RemoteKnownDevice)
    case connecting(LocalKnownDevice)
    case connected(LocalKnownDevice)
    case disconnecting(LocalKnownDevice)
    case disconnected(LocalKnownDevice)
  }
}

extension Device.State {
  public var isKnown: Bool {
    switch self {
    case .notNearby, .connecting, .connected, .disconnecting, .disconnected: return true
    case .neverPaired: return false
    }
  }

  public var isKnownLocal: Bool {
    switch self {
    case .connecting, .connected, .disconnecting, .disconnected: return true
    case .neverPaired, .notNearby: return false
    }
  }

  public var isKnownRemote: Bool {
    switch self {
    case .notNearby: return true
    case .neverPaired, .connecting, .connected, .disconnecting, .disconnected: return false
    }
  }

  public var isUnpairedLocal: Bool {
    switch self {
    case .neverPaired: return true
    case .notNearby, .connecting, .connected, .disconnecting, .disconnected: return false
    }
  }
}

extension Device.State {

  public struct LocalUnpairedDevice: Equatable {
    public let rssi: Double

    public init(rssi: Double) {
      self.rssi = rssi
    }
  }

  public struct LocalKnownDevice: Equatable {
    public let rssi: Double

    public init(rssi: Double) {
      self.rssi = rssi
    }
  }

  public struct RemoteKnownDevice: Equatable {

    public init() {}
  }
}
