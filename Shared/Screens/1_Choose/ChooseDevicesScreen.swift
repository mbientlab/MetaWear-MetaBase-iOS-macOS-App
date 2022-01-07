// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI
import SwiftUI

struct ChooseDevicesScreen: View {

    @EnvironmentObject private var factory: UIFactory
    @EnvironmentObject private var bluetooth: BluetoothStateVM
    @EnvironmentObject private var routing: Routing
    @StateObject private var vm: DiscoveryListVM

    /// Locally managed flag to change "splash" and "list" screens, accounting for animation time needed for a transition.
    @State private var shouldShowList: Bool

    init(_ routing: Routing, _ factory: UIFactory) {
        _vm = .init(wrappedValue: factory.makeDiscoveredDeviceListVM())

        // If already navigated around, rebuilds screen to skip the splash screen
        _shouldShowList = .init(initialValue: routing.directlyShowDeviceList)
    }

    var body: some View {
        VStack {
            if shouldShowList { GridRouter() }
            else { NoDevicesFound(shouldShowList: $shouldShowList) }
        }
        .animation(.easeOut, value: vm.listIsEmpty)
        .animation(.easeOut, value: shouldShowList)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .backgroundToEdges(.myBackground)
        .onAppear(perform: vm.didAppear)
        .environmentObject(vm)
#if os(iOS)
        .trackOrientation()
        .navigationBarBackButtonHidden(true)
#endif
    }
}

// MARK: - Grid Router

extension ChooseDevicesScreen {

    /// Contain orientation changes to the grid layout.
    ///
    struct GridRouter: View {

        @Environment(\.namespace) private var namespace

#if os(macOS)
        var body: some View {
            ScanningIndicator()
            WideOneRowGrid()
        }
#else
        @Environment(\.verticalSizeClass) private var vertClass
        @Environment(\.isPortrait) private var isPortrait

        var body: some View {
            if idiom == .iPad && !isPortrait {
                ScanningIndicator()
                    .matchedGeometryEffect(id: "router_scan", in: namespace!)
                WideOneRowGrid()
            } else {
                ScanningIndicator()
                    .matchedGeometryEffect(id: "router_scan", in: namespace!)
                NarrowVerticallySectionedGrid()
            }
        }
#endif

    }
}
