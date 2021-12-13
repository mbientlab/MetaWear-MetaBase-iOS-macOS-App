// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.


import Foundation
import SwiftUI
import Combine
import mbientSwiftUI
import MetaWear
import MetaWearMetadata

struct HistoryScreen: View {

    @EnvironmentObject private var routing: Routing
    @StateObject var vm: HistoryScreenVM

    init(_ factory: UIFactory) {
        _vm = .init(wrappedValue: factory.makeHistoryScreenVM())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Header(vm: vm)

            HStack(alignment: .firstTextBaseline, spacing: .screenInset) {
                AboutColumn()
                    .frame(minWidth: 215)

                VStack {
                    SessionsList()

                    CTAButton(vm.ctaLabel, action: vm.performCTA)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.bottom, .screenInset)
                .layoutPriority(2)
            }
            .padding(.horizontal, .screenInset)
            .padding(.top, 5)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .environmentObject(vm)
        .onAppear(perform: vm.onAppear)
        .onDisappear(perform: vm.onDisappear)
    }
}
