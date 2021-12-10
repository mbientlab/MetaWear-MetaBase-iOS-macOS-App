// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.


import Foundation
import SwiftUI
import Combine
import mbientSwiftUI
import MetaWear
import Metadata

struct HistoryScreen: View {

    @EnvironmentObject private var routing: Routing
    @StateObject var vm: HistoryScreenVM

    init(item: Routing.Item, factory: UIFactory) {
        _vm = .init(wrappedValue: factory.makeHistoryScreenVM(item: item))
    }

    init(routing: Routing, factory: UIFactory) {
        _vm = .init(wrappedValue: factory.makeHistoryScreenVM(item: routing.destination.item!))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Header(vm: vm)

            HStack(alignment: .firstTextBaseline, spacing: .screenInset) {
                AboutColumn()
                    .frame(minWidth: 200)

                VStack {
                    SessionsList()

                    CTAButton(vm.ctaLabel, action: vm.performCTA)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.bottom, .screenInset)
                .layoutPriority(2)
            }
            .padding(.horizontal, .screenInset)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .environmentObject(vm)
        .onAppear(perform: vm.onAppear)
        .onDisappear(perform: vm.onDisappear)
    }
}
