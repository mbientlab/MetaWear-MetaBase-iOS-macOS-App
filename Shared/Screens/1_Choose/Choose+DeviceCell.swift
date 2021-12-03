// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import SwiftUI
import mbientSwiftUI
import MetaWear

extension ChooseDevicesScreen {

    /// Multi-purpose list cell for MetaWear device groups, solo devices, and unknown devices
    ///
    struct DeviceCell: View {

        init(_ item: Routing.Item, factory: UIFactory) {
            _vm = .init(wrappedValue: factory.makeMetaWearItemVM(item))
        }

        @StateObject var vm: KnownItemVM
        @EnvironmentObject private var routing: Routing

        @State private var isHovering = false
        static let width = CGFloat(120)

        var body: some View { 
            VStack(spacing: 15) {
                MobileComponents(isHovering: isHovering, vm: vm)
                StationaryComponents(isHovering: isHovering, vm: vm)
            }
            .frame(width: Self.width)
            .animation(.easeOut, value: isHovering)
            .whenHovered { isHovering = $0 }
            .onTapGesture { vm.connect() }

            .contextMenu { DeviceCell.ContextMenu(vm: vm) }
            .onAppear(perform: vm.onAppear)
            .onDisappear(perform: vm.onDisappear)
            .environmentObject(vm)
        }
    }
}

extension ChooseDevicesScreen.DeviceCell {


    struct ContextMenu: View {

        let vm: KnownItemVM

        var body: some View {
            Button("Rename", action: vm.rename)

            Divider()

            if vm.isGroup {
                Button("Disband group") { vm.disbandGroup() }
            } else {
                Button("Create Group") { vm.group(withItems: []) }
            }

            Divider()

            Menu(vm.isGroup ? "Forget All" : "Forget") {
                Button("Local Device Only") { vm.forgetLocally() }
                Button("Across All Devices") { vm.forgetGlobally() }
            }
        }
    }

    /// Component of the cell that moves up and down in response to user hovering/selection behaviors
    ///
    struct MobileComponents: View {

        var isHovering: Bool
        var vm: ItemVM

        private var imageWidth: CGFloat { 110 }
        private var imageHeight: CGFloat { isHovering ? 150 : 135 }

        var body: some View {
            SFSymbol.connected.image()
                .font(.headline)
                .foregroundColor(.white)
                .opacity(true ? 1 : 0)
                .offset(y: isHovering ? -20 : 0)

            Text(vm.name)
                .font(.system(.title, design: .rounded))
                .offset(y: isHovering ? -20 : 0)
                .foregroundColor(.white)

            image
        }

        var image: some View {
            HStack {
                if vm.isGroup {
                    ForEach(vm.models.prefix(3), id: \.mac) { (id, model) in
                        model.image.image()
                            .resizable()
                            .scaledToFill()
                            .scaleEffect(isHovering ? 1.1 : 1, anchor: .bottom)
                            .frame(width: imageWidth * 0.4, height: imageHeight * 0.4, alignment: .center)
                    }

                } else {
                    (vm.models.first?.model ?? .notFound("")).image.image()
                        .resizable()
                        .scaledToFill()
                        .scaleEffect(isHovering ? 1.1 : 1, anchor: .bottom)
                        .opacity(vm.isLocallyKnown ? 1 : 0.5)
                }
            }
            .frame(width: imageWidth, height: imageHeight, alignment: .center)
        }
    }

    /// Component of the cell that does not move due to user intents
    ///
    struct StationaryComponents: View {

        var isHovering: Bool
        var vm: ItemVM

        @Namespace private var namespace

        var body: some View {
            mac
                .opacity(isHovering ? 1 : 0.75)

            LargeSignalDots(signal: vm.rssi, color: .white)
                .opacity(isHovering ? 1 : 0.75)
        }

        @ViewBuilder var mac: some View {
            VStack {
                ForEach(vm.macs.indices, id: \.self) { index in
                    Text(vm.macs[index])
                        .font(.system(.headline, design: .monospaced))
                        .lineLimit(1)
                        .fixedSize()
                }
            }
            .foregroundColor(.white.opacity(0.8))
        }
    }
}
