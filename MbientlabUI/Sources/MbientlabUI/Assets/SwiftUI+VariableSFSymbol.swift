// Copyright © 2023 by MBIENTLAB, Inc. All rights reserved.

import SwiftUI

extension Label {
  public init(
    _ titleKey: LocalizedStringKey,
    symbol: VariableSFSymbol,
    variableValue: Double?
  ) where Icon == Image, Title == Text {
    self.init {
      Text(titleKey)
    } icon: {
      Image(symbol: symbol, variableValue: variableValue)
    }
  }
}

extension Image {
  public init(symbol: VariableSFSymbol, variableValue: Double?) {
    self.init(
      systemName: symbol.rawValue,
      variableValue: variableValue
    )
  }
}
