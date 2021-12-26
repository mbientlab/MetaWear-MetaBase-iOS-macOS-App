// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI
import MetaWear
import MetaWearSync

extension ChooseDevicesScreen {

    /// For never-connected-before devices or recently "forgotten" devices
    ///
    struct UnknownDeviceCell: View {

        init(unknown device: CBPeripheralIdentifier, factory: UIFactory) {
            _vm = .init(wrappedValue: factory.makeUnknownItemVM(device))
        }

        @StateObject var vm: UnknownItemVM

        var body: some View {
            DeviceCell(state: vm.state, vm: vm)
                .frame(width: .deviceCellWidth)
                .contextMenu {
                    Button("Remember") { vm.connect() }
                }
                .onAppear(perform: vm.onAppear)
                .onDisappear(perform: vm.onDisappear)
        }
    }

    /// For groups or individual MetaWears known locally or via cloud sync
    ///
    struct KnownDeviceCell: View {

        init(_ item: Routing.Item, factory: UIFactory) {
            _vm = .init(wrappedValue: factory.makeMetaWearItemVM(item))
        }

        @StateObject var vm: KnownItemVM

        var body: some View {
            DeviceCell(state: vm.state, vm: vm)
                .contextMenu { ContextMenu(vm: vm) }
                .onDrop(of: [.plainText], delegate: vm)

                .animation(.spring(), value: vm.dropOutcome)
                .environment(\.isDropTarget, vm.dropOutcome != .noDrop)
                .environment(\.dropOutcome, vm.dropOutcome)
                .environment(\.dragProvider, vm.createDragRepresentation)
        }
    }
}

extension ChooseDevicesScreen.KnownDeviceCell {
    struct ContextMenu: View {

        @ObservedObject var vm: KnownItemVM
        @EnvironmentObject private var list: DiscoveryListVM

        var body: some View {
            Button("Rename", action: vm.rename)
            Button("Identify", action: vm.identify)
            Divider()
            groupButtons
            Divider()
            forgetMenu
        }

        @ViewBuilder private var groupButtons: some View {
            if vm.isGroup { disbandGroupSubmenu }
            createNewGroupSubmenu
            mergeGroupsSubmenu
        }

        @ViewBuilder private var disbandGroupSubmenu: some View {
            if vm.deviceCount > 2 {
                Menu("Remove...") {
                    ForEach(vm.metadata) { device in
                        Button(device.name) { vm.removeFromGroup(device.mac) }
                    }
                    Divider()
                    Button("Disband group") { vm.disbandGroup() }
                }
            } else {
                Button("Disband group") { vm.disbandGroup() }
            }
        }

        @ViewBuilder private var createNewGroupSubmenu: some View {
            let nonSelfUngrouped = list.ungrouped.filter { vm.macs.contains($0.mac) == false }
            if nonSelfUngrouped.isEmpty == false {
                Menu(vm.isGroup ? "Add to group..." : "Group with...") {
                    ForEach(nonSelfUngrouped) { ungrouped in
                        Button(ungrouped.name) { vm.group(withItems: [ungrouped]) }
                    }
                }
            }
        }

        @ViewBuilder private var mergeGroupsSubmenu: some View {
            let nonSelfGroups = vm.isGroup ? list.groups.filter { $0.id.uuidString != vm.id } : list.groups
            if nonSelfGroups.isEmpty == false {
                Menu(vm.isGroup ? "Merge with group..." : "Add to group...") {
                    ForEach(nonSelfGroups) { group in
                        Button("\(group.name)") { vm.group(withGroup: group) }
                    }
                }
            }
        }

        private var forgetMenu: some View {
            Menu(vm.isGroup ? "Forget devices..." : "Forget...") {
                Button("For this \(deviceDescriptor) only") { vm.forgetLocally() }
                Button("Across all devices") { vm.forgetGlobally() }
            }
        }

        private let deviceDescriptor: String = {
#if canImport(AppKit)
            return "Mac"
#else
            return UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone"
#endif
        }()
    }
}
