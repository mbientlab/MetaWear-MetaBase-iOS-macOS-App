// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI
import MetaWear


extension ConfigureScreen {

    struct CTAs: View {

        @EnvironmentObject private var vm: ConfigureVM

        var body: some View {
            HStack(alignment: .center, spacing: .screenInset) {

                Spacer()
                if vm.shouldStream { streamRate } else { logFillDuration }
                Spacer()

                toggle
                CTAButton("Start", action: vm.requestStart)
                    .disabled(vm.canStart == false)
            }
            .animation(.easeOut, value: vm.shouldStream)
            .animation(.easeOut, value: vm.config.totalFreq.rateHz)
        }

        private var toggle: some View {
            Picker(selection: $vm.shouldStream) {

                Text("Stream")
                    .tag(true)
                    .help(SFSymbol.stream.accessibilityDescription)

                Text("Log")
                    .tag(false)
                    .help(SFSymbol.log.accessibilityDescription)

            } label: { }
            .pickerStyle(.segmented)
            .fixedSize()
            #if os(macOS)
            .controlSize(.large)
            #endif
        }

        private var streamRate: some View {
            VStack {
                Text(String(int: vm.config.totalFreq.rateHz) + " Hz")
                    .font(.headline)
                    .foregroundColor(vm.config.exceedsStreamableLimit ? .pink : .secondary)

                if vm.config.exceedsStreamableLimit {
                    Text("Bluetooth Low Energy can only stream at 100–120 Hz")
                        .font(.caption)
                        .foregroundColor(.pink)
                }
            }
        }

        private var logFillDuration: some View {
            Text("Log fill time")
                .font(.headline)
        }
    }
}
