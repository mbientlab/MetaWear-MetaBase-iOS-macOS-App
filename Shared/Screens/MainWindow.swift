// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import SwiftUI

// MARK: - MacOS

#if os(macOS)

/// The app's single window. On macOS, SwiftUI does not have a navigation stack. A substitution is provided.
struct MainWindow: View {

    @EnvironmentObject private var routing: Routing
    @EnvironmentObject private var factory: UIFactory

    static let minWidth: CGFloat = 600
    static let minHeight: CGFloat = 450

    var body: some View {
        stackNavigation
            .frame(minWidth: Self.minWidth, minHeight: Self.minHeight)
            .animation(.easeInOut, value: routing.destination)
            .background(Color.accentColor.ignoresSafeArea())
            .background(AlertVendors())
    }

    private var stackNavigation: some View {
        ZStack {
            switch routing.destination {
                case .choose:
                    ChooseDevicesScreen(routing: routing, factory: factory)
                        .transition(.add)

                case .history(_):
                    HistoryScreen()
                        .transition(.add)

                case .moduleConfig(_):
                    ConfigureScreen()
                        .transition(.add)

                case .log(_):
                    ActionScreen()
                        .transition(.add)
                case .stream(_):
                    ActionScreen()
                        .transition(.add)
            }
        }
    }
}

/// In macOS, all lists (aka NSTableViews) are forced to have a clear background. This does not change alternating list background colors.
extension NSTableView {
    open override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        backgroundColor = NSColor.clear
        enclosingScrollView!.drawsBackground = false
    }
}

// MARK: - iOS

#elseif os(iOS)

/// The app's only window scene.
struct MainWindow: View {

    @EnvironmentObject private var routing: Routing
    @EnvironmentObject private var factory: UIFactory

    var body: some View {
        NavigationView {
            ChooseDevicesScreen(routing: routing, factory: factory)
                .background(navigation.accessibilityHidden(true))
        }
        .navigationViewStyle(.automatic)
        .frame(minWidth: 600)
        .background(Color.accentColor.ignoresSafeArea())
        .overlay(AlertVendors())
    }

    private var destination: Binding<Routing.Destination?> {
        Binding(
            get: { routing.destination },
            set: {
                guard let next = $0 else { return }
                routing.setDestination(next, updatingItem: false, item: nil)
            })
    }

    @ViewBuilder private var navigation: some View {
        NavigationLink(
            destination: ChooseDevicesScreen(routing: routing, factory: factory),
            tag: Routing.Destination.choose,
            selection: destination
        ) { EmptyView() }

        NavigationLink(
            destination: HistoryScreen(routing: routing, factory: factory),
            tag: Routing.Destination.choose,
            selection: destination
        ) { EmptyView() }

        NavigationLink(
            destination: ModuleConfiguratorScreen(),
            tag: Routing.Destination.choose,
            selection: destination
        ) { EmptyView() }

        NavigationLink(
            destination: ProgressScreen(),
            tag: Routing.Destination.choose,
            selection: destination
        ) { EmptyView() }
    }
}

#endif
