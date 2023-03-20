// Copyright © 2023 by MBIENTLAB, Inc. All rights reserved.

public struct Scanner {
  public var isScanning: () -> Bool
  public var isScanningStream: () -> AsyncStream<Bool>
  public var startScanning: () -> Void
  public var stopScanning: () -> Void
}
