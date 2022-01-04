// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI

extension ConfigureScreen {

    struct Estimates: View {

        @EnvironmentObject private var vm: ConfigureVM

        var body: some View {
            HStack(alignment: .center, spacing: .screenInset) {

                Spacer()
                if vm.shouldStream {
                    batteryLife
                    streamRate
                } else {
                    logFillDuration
                    batteryLife
                }
                Spacer()
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
            .frame(maxWidth: .infinity, alignment: .center)
        }

        private var logFillDuration: some View {
            HStack {
                SFSymbol.logs.image()
                Text(vm.logLifetime)
            }
            .help("Estimated time to fill onboard memory (assuming empty start)")
            .frame(maxWidth: .infinity, alignment: .center)
        }

        private var batteryLife: some View {
            HStack {
                SFSymbol.battery.image()
                Text(vm.batteryLifetime)
            }
            .help("Estimated battery life (assuming full charge and no Bluetooth)")
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}
