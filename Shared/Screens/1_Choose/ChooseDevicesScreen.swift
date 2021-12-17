// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import SwiftUI

struct ChooseDevicesScreen: View {

    init(_ routing: Routing, _ factory: UIFactory) {
        _vm = .init(wrappedValue: factory.makeDiscoveredDeviceListVM())

        // If already navigated around, rebuilds screen to skip the splash screen
        _shouldShowList = .init(initialValue: routing.directlyShowDeviceList)
    }

    @EnvironmentObject private var bluetooth: BLEStateVM
    @EnvironmentObject private var routing: Routing
    @StateObject private var vm: DiscoveryListVM

    /// Locally managed flag to change "splash" and "list" screens, accounting for animation time needed for a transition.
    @State private var shouldShowList: Bool

    var body: some View {
        VStack {
            if shouldShowList { grid }
            else { NoDevicesFound(shouldShowList: $shouldShowList) }
        }
        .animation(.easeOut, value: vm.listIsEmpty)
        .animation(.easeOut, value: shouldShowList)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear(perform: vm.didAppear)
        .onDisappear(perform: vm.didDisappear)
        .environmentObject(vm)
    }

    @ViewBuilder private var grid: some View {
#if os(macOS)
        ScanningIndicator()

        MacOSGrid()
            .toolbar {
                ToolbarItemGroup(placement: .automatic) {
                    Spacer()
                    EditGroupsButton()
                }
            }
#else
        EmptyView()
#endif
    }
}

