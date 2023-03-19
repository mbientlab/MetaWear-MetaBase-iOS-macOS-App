import MbientlabUI
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
    #endif
  }
}

struct RootView_Previews: PreviewProvider {
  static var previews: some View {
    RootView()
  }
}
