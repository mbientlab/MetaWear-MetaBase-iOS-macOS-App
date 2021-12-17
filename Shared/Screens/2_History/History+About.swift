// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import SwiftUI
import mbientSwiftUI
import MetaWear
import MetaWearSync

extension HistoryScreen {

    struct AboutColumn: View {

        @EnvironmentObject private var vm: HistoryScreenVM

        var body: some View {
            VStack {
                Subhead(label: "About", trailing: {
                    RefreshButton(help: "Refresh", didTap: vm.refresh)
                        .buttonStyle(BorderlessButtonStyle())
                })

                ScrollView {
                    ForEach(vm.items) { vm in
                        Box(vm: vm)
                    }
                }
            }
        }
    }
}

extension HistoryScreen.AboutColumn {

    struct Box: View {

        @ObservedObject var vm: AboutDeviceVM
        @State private var alignment = CGFloat(65)

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                header
                info
                    .font(.body)
            }
            .onPreferenceChange(SubtitleWK.self) { alignment = max($0, alignment) }
            .onAppear(perform: vm.onAppear)
            .onDisappear(perform: vm.onDisappear)
        }

        private var header: some View {
            HStack(spacing: 10) {

                Text(vm.meta.name)
                        .font(.title3)
                        .lineLimit(1)
                        .fixedSize(horizontal: false, vertical: true)
                        .layoutPriority(1)

                Spacer()

                IdentifyByLEDButton(request: vm.identifyByLED, emulator: vm.led)

                MiniMenuButton {
                    Button("Update Firmware") { }
                    Button("Run Diagnostic") { }
                    Divider()
                    Button("Factory Reset") { vm.reset() }
                    Text("Advanced")
                }
            }
        }

        @ViewBuilder private var info: some View {
            HLabel("Pairing", item: vm.connectionRepresentable,     align: alignment)
            HLabel("RSSI", item: vm.rssiRepresentable,              align: alignment)
            HLabel("Battery", item: vm.battery,                     align: alignment)
            HLabel("MAC", item: vm.meta.mac,                        align: alignment)
            HLabel("Serial", item: vm.meta.serial,                  align: alignment)
            HLabel("Model", item: vm.meta.model.name,               align: alignment)
            HLabel("Firmware", item: vm.info.firmwareRevision,      align: alignment)
            HLabel("Hardware", item: vm.info.hardwareRevision,      align: alignment)
        }
    }
}
