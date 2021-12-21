// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI
import MetaWear
import SwiftUI


extension ConfigureScreen {

    struct CTAs: View {

        @EnvironmentObject private var vm: ConfigureVM

        var body: some View {
            HStack(alignment: .center, spacing: .screenInset) {

                Spacer()
                if vm.shouldStream {
                    streamRate
                } else {
                    logFillDuration
                    batteryLife
                }
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
                    .foregroundColor(vm.config.exceedsStreamableLimit ? .myFailure : .mySecondary)

                if vm.config.exceedsStreamableLimit {
                    Text("Bluetooth Low Energy can only stream at 100–120 Hz")
                        .font(.caption)
                        .foregroundColor(.myFailure)
                }
            }
        }

        private var logFillDuration: some View {
            HStack {
                SFSymbol.logs.image()
                Text(vm.logLifetime)
            }
            .help("Estimated time to fill onboard memory (assuming empty start)")
        }

        private var batteryLife: some View {
            HStack {
                SFSymbol.battery.image()
                Text(vm.batteryLifetime)
            }
            .help("Estimated battery life (assuming full charge and no Bluetooth)")
        }
    }
}
