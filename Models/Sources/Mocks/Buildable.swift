// Copyright © 2023 by MBIENTLAB, Inc. All rights reserved.

#if DEBUG
import Foundation

protocol Buildable {
    func setting<Value>(_ keyPath: KeyPath<Self, Value>, _ newValue: Value) -> Self
}
#endif
