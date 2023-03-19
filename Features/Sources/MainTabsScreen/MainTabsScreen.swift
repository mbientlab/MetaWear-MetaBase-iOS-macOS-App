import MbientlabUI

public struct MainTabsScreen: View {

  public init() {}

  @State private var tab = Tabs.record

  public var body: some View {
    TabView(selection: $tab) {
      Color.clear
        .tabItem {
          Label("Devices", symbol: .devices)
        }

      Color.clear
        .tabItem {
          Label("Record", symbol: .record)
        }

      Color.clear
        .tabItem {
          Label("Sessions", symbol: .sessions)
        }
    }
  }
}

struct MainTabsScreen_Previews: PreviewProvider {
  static var previews: some View {
    MainTabsScreen()
  }
}
