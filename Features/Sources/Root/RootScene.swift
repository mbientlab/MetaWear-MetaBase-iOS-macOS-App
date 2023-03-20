import MbientlabFoundation
import MbientlabUI
import MetawearScanner

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
    VStack {
      Text("MetaBase 6.0")
    }
    .padding()
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    RootView()
  }
}
