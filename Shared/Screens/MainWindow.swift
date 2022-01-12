// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI

/// The app's single window. A manual navigation stack is used instead of NavigationView across both iOS and macOS.
struct MainWindow: View {

    @AppStorage(wrappedValue: 0.0, UserDefaults.MetaWear.Keys.didOnboardAppVersion) private var didOnboard
    @EnvironmentObject private var routing: Routing
    @EnvironmentObject private var factory: UIFactory

    var body: some View {
        stackNavigation
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(steadyHeaderBackground, alignment: .top)
            .animation(.easeOut, value: routing.destination)
            .foregroundColor(.myPrimary)
            .toolbar { BluetoothErrorButton.ToolbarIcon() }

    }

    private var showOnboardingSheet: Binding<Bool> {
        .init(get: { didOnboard < CurrentMetaBaseVersion },
              set: { show in if !show { didOnboard = CurrentMetaBaseVersion } })
    }

    private var stackNavigation: some View {
        ZStack {
            if didOnboard >= CurrentMetaBaseVersion {
                switch routing.destination {
                    case .choose:       ChooseDevicesScreen(routing, factory).transition(.add)
                    case .history:      HistoryScreen(factory).transition(.add)
                    case .configure:    ConfigureScreen(factory).transition(.add)
                    case .log:          ActionScreen(factory).transition(.add)
                    case .stream:       ActionScreen(factory).transition(.add)
                    case .downloadLogs: ActionScreen(factory).transition(.add)
                }
            } else {
                Onboarding(factory: factory)
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
