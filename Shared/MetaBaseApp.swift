// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI

@main
struct MetaBaseApp: App {

    @StateObject private var root: Root = .init()

#if os(iOS)
    @UIApplicationDelegateAdaptor(iOSDelegate.self) private var delegate

    var body: some Scene {
        MainScene(root: root)
    }

#elseif os(macOS)
    @NSApplicationDelegateAdaptor(MacDelegate.self) private var delegate

    var body: some Scene {
        MainScene(root: root)
            .windowStyle(.hiddenTitleBar)
            .windowToolbarStyle(.unified)
            .commands { Menus(root: root) }

        MacTitlelessWindow(
            root: root,
            window: .onboarding,
            title: "Welcome to MetaBase 5",
            content: MacOnboardingWindow()
        )

        MacTitlelessWindow(
            root: root,
            window: .migration,
            title: "MetaBase 4 Migration",
            content: MacMigrationWindow()
        )
    }
#endif
}

#if os(iOS)

class iOSDelegate: NSObject, UIApplicationDelegate {

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        idiom == .iPhone ? [.portrait] : [.all]
    }
}

#elseif os(macOS)

class MacDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false
    }
}

/// In macOS, all Lists (backed at the moment by NSTableViews) are forced to have a clear background. The mod below does not change alternating list background colors.
extension NSTableView {
    open override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        backgroundColor = NSColor.clear
        enclosingScrollView?.drawsBackground = false
    }
}

#endif
