// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import SwiftUI
import mbientSwiftUI
import MetaWear
import CoreBluetooth
import MetaWearMetadata

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
        static let spacing = CGFloat(20)
        static let verticalHoverDelta = CGFloat(20)

        var body: some View {
            VStack(spacing: Self.spacing) {
                MobileComponents(
                    isHovering: isHovering,
                    connection: vm.connection,
                    name: vm.name,
                    models: vm.models,
                    isLocallyKnown: vm.isLocallyKnown,
                    isGroup: vm.isGroup,
                    ledEmulator: vm.ledVM
                )
                StationaryComponents(
                    isHovering: isHovering,
                    isLocallyKnown: vm.isLocallyKnown,
                    rssi: vm.rssi,
                    requestIdentify: vm.identify,
                    isIdentifying: vm.isIdentifying
                )
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
        let deviceDescriptor: String = {
#if canImport(AppKit)
            return "Computer"
#else
            return UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone"
#endif
        }()

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
                Button("For This \(deviceDescriptor) Only") { vm.forgetLocally() }
                Button("For All Devices") { vm.forgetGlobally() }
            }
        }
    }

    /// Component of the cell that moves up and down in response to user hovering/selection behaviors
    ///
    struct MobileComponents: View {

        var isHovering: Bool
        var connection: CBPeripheralState
        var name: String
        var models: [(mac: String, model: MetaWear.Model)]
        var isLocallyKnown: Bool
        var isGroup: Bool
        let ledEmulator: MWLED.FlashPattern.Emulator

        private var imageWidth: CGFloat { 110 }
        private var imageHeight: CGFloat { isHovering ? 150 : 135 }
        static let verticalHoverDelta = ChooseDevicesScreen.DeviceCell.verticalHoverDelta

        var body: some View {
            ConnectionButton(state: connection)
                .opacity(connection == .connected ? 1 : 0)
                .offset(y: isHovering ? -Self.verticalHoverDelta : 0)

            Text(name)
                .font(.system(.title, design: .rounded))
                .offset(y: isHovering ? -Self.verticalHoverDelta : 0)
                .foregroundColor(.white)

            image
        }


        var image: some View {
            HStack {
                if isGroup {
                    ForEach(models.prefix(3), id: \.mac) { (id, model) in
                        MetaWearWithLED(
                            width: imageWidth * 0.4,
                            height: imageHeight * 0.4,
                            isLocallyKnown: isLocallyKnown,
                            isHovering: isHovering,
                            mac: id,
                            model: model,
                            ledEmulator: ledEmulator
                        )
                    }

                } else {
                    MetaWearWithLED(
                        width: imageWidth,
                        height: imageHeight,
                        isLocallyKnown: isLocallyKnown,
                        isHovering: isHovering,
                        mac: models.first?.mac ?? "Unknown",
                        model: models.first?.model ?? .unknown,
                        ledEmulator: ledEmulator
                    )
                }
            }
            .frame(width: imageWidth, height: imageHeight, alignment: .center)
        }


    }

    /// Component of the cell that does not move due to user intents
    ///
    struct StationaryComponents: View {

        var isHovering: Bool
        var isLocallyKnown: Bool
        var rssi: SignalLevel

        let requestIdentify: () -> Void
        var isIdentifying: Bool

        @Namespace private var namespace

        var body: some View {

            SFSymbol.icloud.image()
                .font(.headline)
                .help(Text("Synced via iCloud"))
                .accessibilityLabel(Text(SFSymbol.icloud.accessibilityDescription))
                .opacity(isLocallyKnown ? 0 : 0.75)
                .animation(.easeOut, value: isLocallyKnown)

            LargeSignalDots(signal: rssi, color: .white)
                .opacity(isHovering ? 1 : 0.75)
                .padding(.top, 20)

            Button { requestIdentify() } label: {
                ZStack {

                    Text("Identify")
                        .font(.headline)
                        .lineLimit(1)
                        .fixedSize()
                        .opacity(isIdentifying ? 0 : 1)

                    ProgressView()
                        .opacity(isIdentifying ? 1 : 0)
                        .progressViewStyle(.circular)
                        #if os(macOS)
                        .controlSize(.small)
                        #endif

                }
            }
            .buttonStyle(.borderless)
            .allowsHitTesting(isLocallyKnown)
            .disabled(isLocallyKnown == false)
            .opacity(isLocallyKnown ? 1 : 0)
            .animation(.easeInOut, value: isIdentifying)
            .opacity(isHovering || isIdentifying ? 1 : 0)
        }
    }
}
