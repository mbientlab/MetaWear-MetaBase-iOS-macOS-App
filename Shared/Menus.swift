// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI

#if os(macOS)

struct Menus: Commands {
    @Environment(\.openURL) private var open

    var body: some Commands {
#if DEBUG
        CommandMenu("Debug") {
            Button("Wipe UserDefaults, Keeping MetaWears") { wipeDefaults(preserveMetaWearData: true) }
            Button("Wipe All UserDefaults") { wipeDefaults(preserveMetaWearData: false) }
            Button("Reset Onboarding State") { wipeOnboarding() }
        }
#endif
        CommandGroup(replacing: .newItem) {
            Button("Import MetaBase 4 Data") { open.callAsFunction(ExternalEvent.migrate.url) }
        }

        CommandGroup(replacing: .help) {
            Button("What's New?") { open.callAsFunction(ExternalEvent.onboarding.url) }
        }
        
    }
}

#endif
