// Copyright © 2023 by MBIENTLAB, Inc. All rights reserved.
#if DEBUG
import Combine
import ComposableArchitecture

extension Scanner {

  static let mock: Scanner = {
    let state = CurrentValueSubject<Bool, Never>(false)
    return Self(
      isScanning: { state.value },
      isScanningStream: { state.values.eraseToStream() },
      startScanning: { state.send(true) },
      stopScanning: { state.send(false) }
    )
  }()

  static let testFailures = Self(
    isScanning: unimplemented(placeholder: false),
    isScanningStream: unimplemented(placeholder: .never),
    startScanning: unimplemented(placeholder: ()),
    stopScanning: unimplemented(placeholder: ())
  )
}
#endif
