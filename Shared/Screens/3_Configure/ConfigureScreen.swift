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
                .keyboardShortcut(.cancelAction)
            
            EditableSubhead(
                label: vm.sessionNameBinding,
                placeholder: "Session Name",
                trailing: { PresetsMenu().padding(.trailing, .screenInset) }
            ).padding(.horizontal, .screenInset)

            ScrollView {
                Grid()
                    .padding(.leading, .screenInset)
                    .padding(.top, 15)
            }

            HStack {
                Estimates()
                    .frame(maxWidth: 450, alignment: .center)
                    .frame(maxWidth: .infinity, alignment: .center)
                CTAs()
            }
            .padding(.bottom, .screenInset)
            .padding(.horizontal, .screenInset)
            .layoutPriority(10)
        }
        .animation(.easeInOut, value: vm.selectedPreset)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .environmentObject(vm)
    }
}

