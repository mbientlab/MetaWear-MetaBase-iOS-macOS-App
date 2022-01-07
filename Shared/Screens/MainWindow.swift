// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI

// MARK: - MacOS

#if os(macOS)

/// The app's single window. On macOS, SwiftUI does not have a navigation stack. A substitution is provided.
struct MainWindow: View {

    @EnvironmentObject private var routing: Routing
    @EnvironmentObject private var factory: UIFactory
    @Namespace private var namespace

    static let minWidth: CGFloat = 1100 // ConfigureScreen showing 3 tiles w/ equal margins (635) + extra width (90)
    static let minHeight: CGFloat = 675 // ConfigureScreen showing 2 tile rows (585)

    var body: some View {
//        Onboarding(factory: factory)
        stackNavigation
            .frame(minWidth: Self.minWidth, minHeight: Self.minHeight)
            .background(steadyHeaderBackground, alignment: .top)
            .animation(.easeOut, value: routing.destination)
            .foregroundColor(.myPrimary)
            .environment(\.namespace, namespace)
            .toolbar { BluetoothErrorButton.ToolbarIcon() }
    }

    private var stackNavigation: some View {
        ZStack {
            switch routing.destination {
                case .choose:       ChooseDevicesScreen(routing, factory).transition(.add)
                case .history:      HistoryScreen(factory).transition(.add)
                case .configure:    ConfigureScreen(factory).transition(.add)
                case .log:          ActionScreen(factory).transition(.add)
                case .stream:       ActionScreen(factory).transition(.add)
                case .downloadLogs: ActionScreen(factory).transition(.add)
            }
        }
    }

    @ViewBuilder private var steadyHeaderBackground: some View {
        if routing.destination != .choose {
            Color.myBackground
                .edgesIgnoringSafeArea(.all)
                .frame(height: .headerMinHeight + .headerTopPadding)
        }
    }
}

#if os(macOS)
/// In macOS, all Lists (aka NSTableViews) are forced to have a clear background. This does not change alternating list background colors.
extension NSTableView {
    open override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        backgroundColor = NSColor.clear
        enclosingScrollView?.drawsBackground = false
    }
}
#endif
