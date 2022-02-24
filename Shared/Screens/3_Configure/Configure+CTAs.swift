// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI
import MetaWear

extension ConfigureScreen {

    struct CTAs: View {

        @EnvironmentObject private var vm: ConfigureVM

        @AppStorage(UserDefaults.MetaWear.Keys.didOnboardRemoteMode)
        private var didOnboardRemote = false

        var body: some View {
            HStack(alignment: .center, spacing: .screenInset) {
                HighlightedSegmentedControl(selection: $vm.mode, hoverDelay: didOnboardRemote ? 1 : 0.25)
                CTAButton("Start", action: vm.requestStart)
                    .disabled(vm.canStart == false)
            }
            .animation(.easeOut, value: vm.mode)
            .animation(.easeOut, value: vm.config.totalFreq.rateHz)
        }
    }
}
