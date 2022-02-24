// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI
import MetaWear

extension ConfigureScreen {

    struct CTAs: View {

        @EnvironmentObject private var vm: ConfigureVM

        var body: some View {
            HStack(alignment: .center, spacing: .screenInset) {
                HighlightedSegmentedControl(selection: $vm.shouldStream)
                CTAButton("Start", action: vm.requestStart)
                    .disabled(vm.canStart == false)
            }
            .animation(.easeOut, value: vm.shouldStream)
            .animation(.easeOut, value: vm.config.totalFreq.rateHz)
        }
    }
}
