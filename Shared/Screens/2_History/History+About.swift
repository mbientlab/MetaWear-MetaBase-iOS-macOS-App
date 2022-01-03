// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI
import MetaWear
import MetaWearSync

extension HistoryScreen {

    struct AboutColumn: View {

        @EnvironmentObject private var vm: HistoryScreenVM
        @State private var showDetails = false

        var body: some View {
            VStack {
                Subhead(label: "About", trailing: {
                    RefreshButton(help: "Refresh", didTap: vm.refresh)
                        .buttonStyle(HoverButtonStyle())
                })

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 40) {
                        ForEach(vm.items) { vm in
                            AboutBox(vm: vm, showDetails: $showDetails)
                        }
                    }
                    .padding(.bottom, 25)
                    .animation(.spring(), value: showDetails)
                }
            }
        }
    }
}

extension HistoryScreen.AboutColumn {

    struct AboutBox: View {

        @ObservedObject var vm: AboutDeviceVM
        @Binding var showDetails: Bool
        @State private var alignment = CGFloat(65)

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {

                header
                    .padding(.horizontal, 8)
                    .background(headerShading)
                    .padding(.bottom, 5)

                info
                    .padding(.leading, 10)
                    .font(.body)
            }
            .onPreferenceChange(SubtitleWK.self) { alignment = max($0, alignment) }
            .onAppear(perform: vm.onAppear)
            .onDisappear(perform: vm.onDisappear)
        }

        private var header: some View {
            let verticalPadding: CGFloat = 8
            return HStack(spacing: 10) {

                Text(vm.meta.name)
                    .font(.title3.weight(.medium))
                    .foregroundColor(.myPrimary)
                    .lineLimit(1)
                    .fixedSize(horizontal: false, vertical: true)
                    .layoutPriority(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, verticalPadding)

                IdentifyByLEDButton(flashScale: 2, request: vm.identifyByLED, emulator: vm.led)

                MiniMenuButton {
                    Button("Update Firmware") { }
                    Button("Run Diagnostic") { }
                    Divider()
                    Button("Factory Reset") { vm.reset() }
                    Text("Advanced")
                }
                .padding(.vertical, verticalPadding)
            }
            .clipShape(RoundedRectangle(cornerRadius: 6)) // LED Button
        }

        private var headerShading: some View {
            RoundedRectangle(cornerRadius: 6)
                .foregroundColor(.myGroupBackground)
        }

        @ViewBuilder private var info: some View {
            HLabel("Pairing", align: alignment) {
                Text(vm.connectionRepresentable)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .overlay(connectingSpinner, alignment: .trailing)
            }
            HLabel("RSSI", item: vm.rssiRepresentable,              align: alignment)
            HLabel("Battery", item: vm.battery,                     align: alignment)
            if showDetails {
                HLabel("MAC", item: vm.meta.mac,                        align: alignment)
                HLabel("Serial", item: vm.meta.serial,                  align: alignment)
                HLabel("Model", item: vm.meta.model.name,               align: alignment)
                HLabel("Firmware", item: vm.info.firmwareRevision,      align: alignment)
                HLabel("Hardware", item: vm.info.hardwareRevision,      align: alignment)
            } else {
                Button("More...") { showDetails.toggle() }
                    .buttonStyle(HoverButtonStyle(inactiveColor: .myTertiary))
                    .font(.subheadline)
            }
        }

        @ViewBuilder private var connectingSpinner: some View {
            if vm.connection == .connecting {
                ProgressSpinner()
                    .padding(.trailing, 10)
            }
        }
    }
}
