// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI


#if os(iOS)

@main
struct MetaBaseApp: App {
    @UIApplicationDelegateAdaptor(iOSDelegate.self) private var delegate
    @StateObject private var root: Root = .init()

    var body: some Scene {
        WindowGroup("MetaBase", id: Windows.metabaseMain.tag) {
            Namespaced(MainWindow())
                .onAppear { root.start() }
                .environmentObject(root.bluetoothVM)
                .environmentObject(root.factory)
                .environmentObject(root.routing)
        }
    }
}

class iOSDelegate: NSObject, UIApplicationDelegate {

}

#elseif os(macOS)

@main
struct MetaBaseApp: App {

    @StateObject private var root: Root = .init()
    @NSApplicationDelegateAdaptor(MacDelegate.self) private var delegate

    var body: some Scene {
        WindowGroup("MetaBase", id: Windows.metabaseMain.tag) {
            Namespaced(MainWindow())
                .onAppear { root.start() }
                .environmentObject(root.bluetoothVM)
                .environmentObject(root.factory)
                .environmentObject(root.routing)
                .frame(minWidth: MainScene.minWidth, minHeight: MainScene.minHeight)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
        .commands { Menus() }

        macOS
    }

    @SceneBuilder var macOS: some Scene {
        WindowGroup("Welcome to MetaBase 5", id: Windows.onboarding.tag) {
            Namespaced(MacOnboardingWindow())
                .environmentObject(root.factory)
                .handlesExternalEvents(preferring: [Windows.onboarding.tag], allowing: [])
        }
        .handlesExternalEvents(matching: [Windows.onboarding.tag])
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: false))

        WindowGroup("MetaBase 4 Migration", id: Windows.migration.tag) {
            Namespaced(MacMigrationWindow())
                .handlesExternalEvents(preferring: [Windows.migration.tag], allowing: [])
                .environmentObject(root.factory)
        }
        .handlesExternalEvents(matching: [Windows.migration.tag])
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
    }
}

class MacDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false
    }
}

/// In macOS, all Lists (aka NSTableViews) are forced to have a clear background. This does not change alternating list background colors.
extension NSTableView {
    open override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        backgroundColor = NSColor.clear
        enclosingScrollView?.drawsBackground = false
    }
}

#endif
