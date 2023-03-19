import MbientlabUI

struct Sidebar: View {
  var body: some View {
    List {
      Section("Devices") {
        NavigationLink(
          value: "X",
          label: { Text("Ankle (L)") }
        )
        NavigationLink(
          value: "X",
          label: { Text("Ankle (R)") }
        )
        NavigationLink(
          value: "X",
          label: { Text("Strap") }
        )
      }

      Section("Record") {
        NavigationLink(
          value: "X",
          label: { Text("Range of motion") }
        )
        NavigationLink(
          value: "X",
          label: { Text("Gait") }
        )
      }

      Section("Sessions") {
        Text("All...")
      }
    }
    .listStyle(.sidebar)
    .toolbar {
      ToolbarItemGroup {
        Spacer()
        Menu {
          Button("New recording configuration") { }
          Divider()
          Section("Nearby Metawear") {
            Text("No unpaired devices found nearby")
          }
        } label: {
          Label("Add", symbol: .add)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
      }
    }
  }
}
