// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI
import SwiftUI

struct ChooseDevicesScreen: View {

    @EnvironmentObject private var factory: UIFactory
    @EnvironmentObject private var bluetooth: BluetoothStateVM
    @EnvironmentObject private var routing: Routing
    @StateObject private var vm: DiscoveryListVM
    @Environment(\.colorScheme) private var colorScheme

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
#if os(iOS)
        .background(atomIconShine.alignmentGuide(.top) { $0[VerticalAlignment.center] }, alignment: .top)
        .background(vignette.edgesIgnoringSafeArea(.all), alignment: .topLeading)
        .background(screenShine)
#endif
        .backgroundToEdges(.myBackground)
        .onAppear(perform: vm.didAppear)
        .environmentObject(vm)
#if os(iOS)
        .trackOrientation()
#endif
    }

    private var vignette: some View {
        DigitalVignette(background: .myVignette,
                        blendMode: colorScheme == .dark ? .lighten : .plusDarker)
            .opacity(shouldShowList ? 1 : 0)
    }

    @ViewBuilder private var screenShine: some View {
        if colorScheme == .light {
            SoftSpotlight(color: .white.opacity(0.9), radius: 500)
        }
    }

    @ViewBuilder private var atomIconShine: some View {
        if shouldShowList, idiom == .iPhone, shouldShowList, colorScheme == .light {
            SoftSpotlight(color: .white.opacity(0.9), radius: 180)
        }
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
        @Environment(\.isPortrait) private var isPortrait
        private let scanTag = "router_scan"
        private var useWideGrid: Bool { idiom == .iPad && !isPortrait }

        var body: some View {
            if useWideGrid {
                ScanningIndicator()
                    .matchedGeometryEffect(id: scanTag, in: namespace!)
                WideOneRowGrid()
            } else {
                ScanningIndicator()
                    .matchedGeometryEffect(id: scanTag, in: namespace!)
                    .padding(.vertical, 60)
                NarrowVerticallySectionedGrid()
            }
        }
#endif

    }
}
