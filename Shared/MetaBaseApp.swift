// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI

@main
struct MetaBaseApp: App {

    @StateObject private var root: Root = .init()
#if os(macOS)
    @NSApplicationDelegateAdaptor(MacDelegate.self) private var delegate
#elseif os(iOS)
    @UIApplicationDelegateAdaptor(iOSDelegate.self) private var delegate
#endif

    var body: some Scene {
        MainScene(root: root)
        OnboardingScene(root: root)
        MigrateScene(root: root)
    }
}

#if os(macOS)
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

#elseif os(iOS)

class iOSDelegate: NSObject, UIApplicationDelegate {

}
#endif
