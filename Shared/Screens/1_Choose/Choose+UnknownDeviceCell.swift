// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import SwiftUI
import mbientSwiftUI
import MetaWear
import MetaWearMetadata

extension ChooseDevicesScreen {

    /// Multi-purpose list cell for MetaWear device groups, solo devices, and unknown devices
    ///
    struct UnknownDeviceCell: View {

        init(unknown device: CBPeripheralIdentifier, factory: UIFactory) {
            _vm = .init(wrappedValue: factory.makeUnknownItemVM(device))
        }

        @StateObject var vm: UnknownDeviceVM
        @EnvironmentObject private var routing: Routing

        @State private var isHovering = false

        var body: some View {
            VStack(spacing: DeviceCell.spacing) {
                DeviceCell.MobileComponents(
                    isHovering: isHovering,
                    connection: vm.connection,
                    name: vm.name,
                    models: vm.models,
                    isLocallyKnown: vm.isLocallyKnown,
                    isGroup: vm.isGroup,
                    ledEmulator: .init(preset: .eight)
                )
                DeviceCell.StationaryComponents(
                    isHovering: isHovering,
                    isLocallyKnown: vm.isLocallyKnown,
                    rssi: vm.rssi,
                    requestIdentify: { },
                    isIdentifying: false
                )
            }
            .frame(width: DeviceCell.width)
            .animation(.easeOut, value: isHovering)
            .whenHovered { isHovering = $0 }
            .onTapGesture { vm.connect() }
            .contextMenu {
                Button("Connect") { vm.connect() }
            }
            .onAppear(perform: vm.onAppear)
            .onDisappear(perform: vm.onDisappear)
            .environmentObject(vm)
        }
    }
}
