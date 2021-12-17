// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import SwiftUI
import mbientSwiftUI
import MetaWear
import MetaWearSync

extension ChooseDevicesScreen {
    
    /// Multi-purpose list cell for MetaWear device groups, solo devices, and unknown devices
    ///
    struct UnknownDeviceCell: View {
        
        init(unknown device: CBPeripheralIdentifier, factory: UIFactory) {
            _vm = .init(wrappedValue: factory.makeUnknownItemVM(device))
        }
        
        @StateObject var vm: UnknownItemVM
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
                    .onTapGesture { vm.connect() }
                    .onDrag(vm.createDragRepresentation)
                
                DeviceCell.StationaryComponents(
                    isHovering: isHovering,
                    isLocallyKnown: vm.isLocallyKnown,
                    isCloudSynced: vm.isCloudSynced,
                    rssi: vm.rssi,
                    isConnecting: vm.connection == .connecting,
                    identifyHelpText: "",
                    requestIdentify: { },
                    isIdentifying: false
                )
            }
            .frame(width: DeviceCell.width)
            .animation(.easeOut, value: isHovering)
            .animation(.easeOut, value: vm.connection)
            .whenHovered { isHovering = $0 }
            
            .contextMenu {
                Button("Connect") { vm.connect() }
            }
            .onAppear(perform: vm.onAppear)
            .onDisappear(perform: vm.onDisappear)
            .environmentObject(vm)
        }
    }
}
