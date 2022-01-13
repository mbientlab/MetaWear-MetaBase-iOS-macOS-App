// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI

/// The app's single window. A manual navigation stack is used instead of NavigationView across both iOS and macOS.
struct MainWindow: View {

    @EnvironmentObject private var routing: Routing
    @EnvironmentObject private var factory: UIFactory

    var body: some View {
        stackNavigation
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(steadyHeaderBackground, alignment: .top)
            .animation(.easeOut, value: routing.destination)
            .foregroundColor(.myPrimary)
#if os(macOS)
            .toolbar { BluetoothErrorButton.ToolbarIcon() }
#endif
    }

    private var stackNavigation: some View {
        ZStack {
            switch routing.destination {
                case .choose:
                    ChooseDevicesScreen(routing, factory).transition(.add)
#if os(iOS)
                        .overlay(OnboardingFooter_iOS(), alignment: .bottom)
#elseif os(macOS)
                        .background(OnboardingLauncher_macOS())
#endif
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
                .frame(height: .headerMinHeight + .headerTopPadding + 10)
        }
    }
}
