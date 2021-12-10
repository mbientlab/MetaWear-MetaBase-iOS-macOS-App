// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import SwiftUI
import mbientSwiftUI
import Combine
import MetaWear
import Metadata

struct ActionScreen: View {

    @StateObject private var vm: ActionLogVM

    init(item: Routing.Item, factory: UIFactory) {
        _vm = .init(wrappedValue: factory.makeActionLogVM(item: item))
    }

    init(routing: Routing, factory: UIFactory) {
        _vm = .init(wrappedValue: factory.makeActionLogVM(item: routing.destination.item!))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ActionHeader(vm: vm)

            ScrollView {

                ForEach(vm.deviceVMs) { vm in
                    Row(vm: vm)
                }
                .animation(.easeOut, value: vm.programmingFocus)
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
