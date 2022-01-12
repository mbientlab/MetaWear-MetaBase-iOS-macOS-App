// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI

struct MainScene: Scene {

    let root: Root

    // ConfigureScreen showing 3 tiles w/ equal margins (635) + extra width (90)
    static let minWidth: CGFloat = 1100

    // ConfigureScreen showing 2 tile rows (585)
    static let minHeight: CGFloat = 675

    var body: some Scene {
        WindowGroup {
            Namespaced(MainWindow())
                .onAppear { root.start() }
                .environmentObject(root.bluetoothVM)
                .environmentObject(root.factory)
                .environmentObject(root.routing)
                .handleOnlyEvents(ExternalEvent.launch)
#if os(macOS)
                .frame(minWidth: Self.minWidth, minHeight: Self.minHeight)
#endif
        }
        .handleOnlyEvents(ExternalEvent.launch)
#if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
        .commands { Menus() }
#endif
    }
}

struct OnboardingScene: Scene {

    let root: Root

    var body: some Scene {
        WindowGroup("Welcome") {
            Namespaced(Content())
                .environmentObject(root.factory)
                .handleOnlyEvents(ExternalEvent.onboarding)
        }
        .handleOnlyEvents(ExternalEvent.onboarding)
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
    }

    struct Content: View {
        @EnvironmentObject var factory: UIFactory
        var body: some View {
            Onboarding(importer: factory.makeImportVM(),
                       vm: factory.makeOnboardingVM())
                .frame(minWidth: 900, minHeight: MainScene.minHeight)
        }
    }
}

struct MigrateScene: Scene {

    let root: Root

    var body: some Scene {
        WindowGroup("Migrate Data") {
            Namespaced(Content())
                .handleOnlyEvents(ExternalEvent.migrate)
                .environmentObject(root.factory)
        }
        .handleOnlyEvents(ExternalEvent.migrate)
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
    }

    struct Content: View {
        @EnvironmentObject var factory: UIFactory
        var body: some View {
            Onboarding(importer: factory.makeImportVM(),
                       vm: factory.makeMigrationVM())
                .frame(minWidth: 900, minHeight: MainScene.minHeight)
        }
    }
}
