// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI

extension ConfigureScreen {

    struct Estimates: View {

        @EnvironmentObject private var vm: ConfigureVM

        var body: some View {
            HStack(alignment: .center, spacing: .screenInset) {

                batteryLife

                if vm.shouldStream {
                    streamRate
                } else {
                    logFillDuration
                }
            }
            .animation(.easeOut, value: vm.shouldStream)
            .animation(.easeOut, value: vm.config.totalFreq.rateHz)
        }

        private var streamRate: some View {
            
            HStack {
                if vm.config.exceedsStreamableLimit {
                    WarningPopover(message: "Bluetooth Low Energy can only stream at 100–120 Hz",
                                   color: .myFailure)
                } else {
                    SFSymbol.signal.image()
                }
                Text(vm.frequencyLabel)
                    .font(.headline)
                    .foregroundColor(vm.config.exceedsStreamableLimit ? .myFailure : .mySecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }

        private var logFillDuration: some View {
            HStack {
                SFSymbol.logs.image()
                Text(vm.logLifetime)
                    .lineLimit(1)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .help("Estimated time to fill onboard memory (assuming empty start)")
            .frame(maxWidth: .infinity, alignment: .leading)
        }

        private var batteryLife: some View {
            HStack {
                SFSymbol.battery.image()
                Text(vm.batteryLifetime)
                    .lineLimit(1)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .help("Estimated battery life (assuming full charge and no Bluetooth)")
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
