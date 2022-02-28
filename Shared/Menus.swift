// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI

#if os(macOS)

struct Menus: Commands {
    @Environment(\.openURL) private var open
    let root: Root

    var body: some Commands {
#if DEBUG
        CommandMenu("Debug") {
            DebugMenu()
        }
#endif

        CommandGroup(replacing: .newItem) {
            if root.importer.couldImportState {
                Button("Import MetaBase 4 Data") { open(window: .migration) }
            }
        }

        CommandGroup(replacing: .help) {
            Button("What's New in MetaBase 5?") { open(window: .onboarding) }
        }

        CommandGroup(before: .windowList) {
            Button("Focus Main Window") { open(window: .metabaseMain) }
        }
    }

    func open(window target: Windows) {
        for window in NSApp.windows {
            guard let id = window.identifier?.rawValue else { continue }
            if id.hasPrefix(target.tag) {
                window.makeKeyAndOrderFront(nil)
                return
            }
        }
        // Resort to SwiftUI open only if there isn't an existing window for that identifier
        open.callAsFunction(target.externalEventURL)
    }
}

#endif
#if DEBUG
struct DebugMenu: View {

    var body: some View {
#if os(macOS)
        Button("Kill Windows") { NSApp.windows.forEach { $0.close() } }
#endif
        Button("Wipe UserDefaults, Keeping MetaWears") { wipeDefaults(preserveMetaWearData: true) }
        Button("Wipe All UserDefaults") { wipeDefaults(preserveMetaWearData: false) }
        Button("Reset Onboarding State") { wipeOnboarding() }
        Button("Wipe iCloud Session Data") { wipeCloudSessionData() }
    }
}
#endif
