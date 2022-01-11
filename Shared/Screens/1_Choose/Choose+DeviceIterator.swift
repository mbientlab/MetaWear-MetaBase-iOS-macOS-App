// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI

// MARK: - Sectioned

extension ChooseDevicesScreen {

    struct DeviceIterator {
        private init() { }

        struct KnownGroups: View {
            @EnvironmentObject private var vm: DiscoveryListVM
            @EnvironmentObject private var factory: UIFactory
            @Environment(\.namespace) private var list
            var body: some View {
                ForEach(vm.groups) { group in
                    KnownDeviceCell(.group(group.id), factory: factory)
                }
            }
        }

        struct KnownUngrouped: View {
            @EnvironmentObject private var vm: DiscoveryListVM
            @EnvironmentObject private var factory: UIFactory
            @Environment(\.namespace) private var list
            var body: some View {
                ForEach(vm.ungrouped) { metadata in
                    KnownDeviceCell(.known(metadata.id), factory: factory)
                }
            }
        }

        struct UnknownNearby: View {
            @EnvironmentObject private var vm: DiscoveryListVM
            @EnvironmentObject private var factory: UIFactory
            @Environment(\.namespace) private var list
            var body: some View {
                ForEach(vm.unknown) { deviceID in
                    UnknownDeviceCell(unknown: deviceID, factory: factory)
                }
            }

        }
    }
}
