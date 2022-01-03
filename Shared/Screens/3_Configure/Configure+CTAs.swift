// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI
import MetaWear
import SwiftUI

extension ConfigureScreen {

    struct CTAs: View {

        @EnvironmentObject private var vm: ConfigureVM

        var body: some View {
            HStack(alignment: .center, spacing: .screenInset) {
                styledToggle
                CTAButton("Start", action: vm.requestStart)
                    .disabled(vm.canStart == false)
            }
            .animation(.easeOut, value: vm.shouldStream)
            .animation(.easeOut, value: vm.config.totalFreq.rateHz)
        }

        private var styledToggle: some View {
            Toggle(isOn: $vm.shouldStream, label: { })
                .toggleStyle(HighlightToggleStyle(off: "Log", on: "Stream"))
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
    }
}
