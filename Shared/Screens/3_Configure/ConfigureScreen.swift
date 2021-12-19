// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI
import MetaWear

struct ConfigureScreen: View {

    @StateObject private var vm: ConfigureVM

    init(_ factory: UIFactory) {
        _vm = .init(wrappedValue: factory.makeConfigureVM())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Header(vm: vm)

            Subhead(
                label: vm.selectedPreset?.name ?? "New Session",
                trailing: { PresetsMenu() }
            ).padding(.horizontal, .screenInset)

            ScrollView {
                Grid()
                    .padding(.leading, .screenInset)
                    .padding(.top, 15)
            }

            CTAs()
                .padding(.bottom, .screenInset)
                .padding(.horizontal, .screenInset)
        }
        .animation(.easeInOut, value: vm.selectedPreset)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .environmentObject(vm)
    }
}
