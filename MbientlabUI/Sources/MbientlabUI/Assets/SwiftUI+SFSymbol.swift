// Copyright © 2023 by MBIENTLAB, Inc. All rights reserved.

import SwiftUI

extension Label {
  public init(_ titleKey: LocalizedStringKey, symbol: SFSymbol) where Icon == Image, Title == Text {
    self.init(titleKey, systemImage: symbol.rawValue)
  }
}

extension Image {
  public init(symbol: SFSymbol) {
    self.init(systemName: symbol.rawValue)
  }
}
