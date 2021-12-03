// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import SwiftUI
import mbientSwiftUI
import MetaWear
import Metadata

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
        static let width = CGFloat(120)

        var body: some View {
            VStack(spacing: 15) {
                DeviceCell.MobileComponents(isHovering: isHovering, vm: vm)
                DeviceCell.StationaryComponents(isHovering: isHovering, vm: vm)
            }
            .frame(width: Self.width)
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
