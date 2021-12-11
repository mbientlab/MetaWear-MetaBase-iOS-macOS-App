// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation

public extension DispatchQueue {
    /// asyncAfter sugar
    func after(_ wait: TimeInterval, _ execute: @escaping () -> Void) {
        asyncAfter(deadline: .now() + wait) {
            execute()
        }
    }
}
