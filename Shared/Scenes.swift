// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI

struct MainScene: Scene {

    let root: Root
    @Namespace private var namespace

    // ConfigureScreen showing 3 tiles w/ equal margins (635) + extra width (90)
    static let minWidth: CGFloat = 1100

    // ConfigureScreen showing 2 tile rows (585)
    static let minHeight: CGFloat = 675

    var body: some Scene {
        WindowGroup {
            MainWindow()
                .environment(\.namespace, namespace)
                .onAppear { root.start() }
                .environmentObject(root.bluetoothVM)
                .environmentObject(root.factory)
                .environmentObject(root.routing)
#if os(macOS)
                .frame(minWidth: Self.minWidth, minHeight: Self.minHeight)
#endif
        }
#if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
        .commands { Menus() }
#endif
    }
}

struct OnboardingScene: Scene {

    let root: Root
    @Namespace private var namespace

    var body: some Scene {
        WindowGroup("Welcome") {
            Onboarding(factory: root.factory)
                .environment(\.namespace, namespace)
                .frame(minWidth: 900, minHeight: MainScene.minHeight)
                .handleOnlyEvents(ExternalEvent.onboarding)
                .environmentObject(root.factory)
        }
        .handleOnlyEvents(ExternalEvent.onboarding)
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
    }
}
