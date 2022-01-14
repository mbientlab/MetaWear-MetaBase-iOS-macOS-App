// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI
import SwiftUI

struct ChooseDevicesScreen: View {

    init(_ routing: Routing, _ factory: UIFactory) {
        let vm = factory.makeDiscoveredDeviceListVM()
        _vm = .init(wrappedValue: vm)
        _shouldShowList = .init(initialValue: factory.makeOnboardState().didOnboard && vm.didHaveDevicesAtLoad)
    }

    @EnvironmentObject private var factory: UIFactory
    @EnvironmentObject private var bluetooth: BluetoothStateVM
    @EnvironmentObject private var routing: Routing
    @StateObject private var vm: DiscoveryListVM
    @Environment(\.colorScheme) private var colorScheme

    /// Locally managed flag to change "splash" and "list" screens, accounting for animation time needed for a transition.
    @State private var shouldShowList: Bool

    var body: some View {
        VStack {
            if shouldShowList {
                ScanningIndicator()
                    .padding(.top, CGFloat(macOS: 0, iPad: 10, iOS: 60))

                WideOneRowGrid()

            } else { NoDevicesFound(shouldShowList: $shouldShowList) }
        }

        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
#if os(iOS)
        .background(atomIconShine.alignmentGuide(.top) { $0[VerticalAlignment.center] }, alignment: .top)
        .background(vignette.edgesIgnoringSafeArea(.all), alignment: .topLeading)
#endif
        .background(screenShine.edgesIgnoringSafeArea(.all))
        .backgroundToEdges(.myBackground)
        .onAppear(perform: vm.didAppear)
        .environmentObject(vm)
#if os(iOS)
        .trackOrientation()
        .overlay(OnboardingFooter_iOS().opacity(shouldShowList ? 1 : 0), alignment: .bottom)
#elseif os(macOS)
        .background(OnboardingLauncher_macOS())
#endif
        .animation(.easeOut, value: vm.listIsEmpty)
        .animation(.easeOut, value: shouldShowList)
    }

    private var vignette: some View {
        DigitalVignette(background: .myVignette,
                        blendMode: colorScheme == .dark ? .lighten : .plusDarker)
            .opacity(shouldShowList ? 1 : 0)
    }

    @ViewBuilder private var screenShine: some View {
        if colorScheme == .light {
            SoftSpotlight(color: .white.opacity(idiom.is_Mac ? 0.8 : 0.9), radius: 500)
        }
    }

    @ViewBuilder private var atomIconShine: some View {
        if shouldShowList, idiom == .iPhone, shouldShowList, colorScheme == .light {
            SoftSpotlight(color: .white.opacity(0.9), radius: 180)
        }
    }
}
