// Copyright © 2023 by MBIENTLAB, Inc. All rights reserved.

import MbientlabUI
import Devices
import Sessions

public struct MainTabsScreen: View {

  public init() {}

  @State private var tab = Tabs.record

  public var body: some View {
    VStack(spacing: 0) {
      VStack {
        HStack(spacing: 10) {
          ProgressView()
          Text("Downloading...")
            .bold()
        }
        .foregroundColor(.white)
        .tint(.white)
      }
      .frame(maxWidth: .infinity, minHeight: 30, alignment: .center)
      .background(Color.red)
      tabs
    }
  }

  var tabs: some View {
    TabView(selection: $tab) {
      DevicesTabView()
        .tag(Tabs.devices)
        .tabItem {
          Label("Sensors", symbol: .devices)
        }

      Color.clear
        .tag(Tabs.record)
        .tabItem {
          Label("Record", symbol: .record)
        }

      SessionsTabView()
        .tag(Tabs.sessions)
        .tabItem {
          Label("Downloads", symbol: .sessions)
        }
    }
  }
}

struct MainTabsScreen_Previews: PreviewProvider {
  static var previews: some View {
    MainTabsScreen()
  }
}
