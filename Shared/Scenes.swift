// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI

struct MainScene: Scene {
    // ConfigureScreen showing 3 tiles w/ equal margins (635) + extra width (90)
    static let minWidth: CGFloat = 1100

    // ConfigureScreen showing 2 tile rows (585)
    static let minHeight: CGFloat = 700

    let root: Root

    var body: some Scene {
        WindowGroup("MetaBase", id: Windows.metabaseMain.tag) {
            Namespaced(RootNavigationController())
                .onAppear { root.start() }
                .environmentObject(root.bluetoothVM)
                .environmentObject(root.factory)
                .environmentObject(root.routing)
                .environmentObject(root.onboard)
#if os(macOS)
                .frame(minWidth: MainScene.minWidth, minHeight: MainScene.minHeight)
#endif
        }
    }
}

// MARK: - Extra Window Scenes (macOS)
#if os(macOS)
struct MacTitlelessWindow<Content: View>: Scene {

    let root: Root
    let window: Windows
    let title: String
    let content: Content

    var body: some Scene {
        WindowGroup(title, id: window.tag) {
            Namespaced(content)
                .environmentObject(root.factory)
                .handlesExternalEvents(preferring: [window.tag], allowing: [])
        }
        .handlesExternalEvents(matching: [window.tag])
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
    }
    
}

struct MacOnboardingWindow: View {
    @EnvironmentObject var factory: UIFactory
    var body: some View {
        OnboardingSession(importer: factory.makeImportVM(),
                          vm: factory.makeOnboardingSessionVM())
            .frame(minWidth: 900, minHeight: MainScene.minHeight)
    }
}

struct MacMigrationWindow: View {
    @EnvironmentObject var factory: UIFactory
    var body: some View {
        MigrationSession(importer: factory.makeImportVM(),
                         vm: factory.makeMigrationVM())
            .frame(minWidth: 900, minHeight: MainScene.minHeight)
    }
}
#endif
