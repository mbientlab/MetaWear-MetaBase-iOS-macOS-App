// Copyright © 2023 by MBIENTLAB, Inc. All rights reserved.

import MbientlabUI
import MainSplitScreen
import MainTabsScreen

public struct RootScene: Scene {

  public init() {}

  public var body: some Scene {
    WindowGroup {
      RootView()
    }
  }
}

struct RootView: View {
  var body: some View {
    #if os(iOS)
    MainTabsScreen()
    #elseif os(macOS)
    MainSplitScreen()
    #endif
  }
}

struct RootView_Previews: PreviewProvider {
  static var previews: some View {
    RootView()
  }
}
