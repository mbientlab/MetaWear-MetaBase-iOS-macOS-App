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
