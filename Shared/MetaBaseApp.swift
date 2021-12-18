// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI

@main
struct MetaBaseApp: App {

    @StateObject private var root: Root = .init()

    var body: some Scene {
        WindowGroup {
            MainWindow()
                .onAppear { root.start() }
                .environmentObject(root.bluetoothVM)
                .environmentObject(root.factory)
                .environmentObject(root.routing)
        }
#if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
#endif
    }
}
