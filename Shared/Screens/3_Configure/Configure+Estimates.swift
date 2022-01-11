// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI

extension ConfigureScreen {

    struct Estimates: View {

        @EnvironmentObject private var vm: ConfigureVM
        @Environment(\.sizeCategory) private var dynamicType
        private var edge: Alignment { idiom == .iPhone && dynamicType.isAccessibilityCategory ? .trailing : .leading }

        var body: some View {
            content
                .adaptiveFont(.estimates)
                .animation(.easeOut, value: vm.shouldStream)
                .animation(.easeOut, value: vm.config.totalFreq.rateHz)
        }

        @ViewBuilder private var content: some View {
            batteryLife

            if vm.shouldStream {
                streamRate
            } else {
                logFillDuration
            }
        }

        private var streamRate: some View {
            EdgeAlignedHStack(
                edge: edge,
                icon: streamRateIcon,
                content: Text(vm.frequencyLabel)
                    .foregroundColor(vm.config.exceedsStreamableLimit ? .myFailure : nil)

            )
                .padding(.horizontal, idiom == .iPhone ? 0 : 40)
                .frame(maxWidth: idiom == .iPhone ? .infinity : nil, alignment: edge)
        }

        @ViewBuilder private var streamRateIcon: some View {
            if vm.config.exceedsStreamableLimit {
                WarningPopover(message: "Bluetooth Low Energy can only stream at 100–120 Hz", color: .myFailure)
            } else {
                SFSymbol.signal.image()
            }
        }

        private var logFillDuration: some View {
            EdgeAlignedHStack(
                edge: edge,
                icon: SFSymbol.logs.image(),
                content: Text(vm.logLifetime)
                    .lineLimit(1)
                    .fixedSize(horizontal: false, vertical: true)
            )
            .help("Estimated time to fill onboard memory (assuming empty start)")
            .frame(maxWidth: .infinity, alignment: edge)
        }

        private var batteryLife: some View {
            EdgeAlignedHStack(
                edge: edge,
                icon: SFSymbol.battery.image(),
                content: Text(vm.batteryLifetime)
                    .lineLimit(1)
                    .fixedSize(horizontal: false, vertical: true)
            )
                .help("Estimated battery life (assuming full charge and no Bluetooth)")
                .frame(maxWidth: .infinity, alignment: edge)
        }
    }
}

fileprivate struct EdgeAlignedHStack<Icon: View, Content: View>: View {
    var edge: Alignment
    var icon: Icon
    var content: Content
    var body: some View {
        HStack {
            if edge == .leading { icon }
            content
            if edge == .trailing { icon }
        }
    }
}
