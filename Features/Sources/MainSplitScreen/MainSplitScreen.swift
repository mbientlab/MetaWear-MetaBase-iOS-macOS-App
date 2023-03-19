// Copyright © 2023 by MBIENTLAB, Inc. All rights reserved.

import MbientlabUI

public struct MainSplitScreen: View {

  public init() {}

  public var body: some View {
    NavigationSplitView(
      sidebar: Sidebar.init,
      detail: { Color.clear }
    )
  }
}
