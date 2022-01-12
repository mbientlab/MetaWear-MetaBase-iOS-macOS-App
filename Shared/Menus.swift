// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI

#if os(macOS)

struct Menus: Commands {
    var body: some Commands {
#if DEBUG
        CommandMenu("Debug") {
            Button("Wipe UserDefaults Local & Cloud") { wipeDefaults() }
            Button("Wipe Onboarding States") { wipeOnboarding() }
        }
#endif
        CommandGroup(replacing: .newItem) {
            // Single window
        }

        CommandGroup(replacing: .help) {
            // No Help
        }
        
    }
}

#endif
