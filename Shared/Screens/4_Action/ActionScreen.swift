// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI
import Combine
import MetaWear
import MetaWearSync

struct ActionScreen: View {

    @StateObject private var vm: ActionVM

    init(_ factory: UIFactory) {
        _vm = .init(wrappedValue: factory.makeActionVM())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ActionHeader(vm: vm)

            ScrollView {

                ForEach(vm.deviceVMs) { vm in
                    Row(vm: vm)
                }
                .animation(.easeOut, value: vm.actionFocus)
            }
            .padding(.horizontal, .screenInset)

            CTAs()
                .padding(.bottom, .screenInset)
                .padding(.horizontal, .screenInset)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .environmentObject(vm)
        .onAppear(perform: vm.start)
    }
}
