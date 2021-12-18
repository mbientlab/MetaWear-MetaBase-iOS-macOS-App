// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.


import Foundation
import Combine
import mbientSwiftUI
import MetaWear
import MetaWearSync
#if os(iOS)
import UIKit
#endif

struct HistoryScreen: View {

    @EnvironmentObject private var routing: Routing
    @StateObject var vm: HistoryScreenVM

    init(_ factory: UIFactory) {
        _vm = .init(wrappedValue: factory.makeHistoryScreenVM())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Header(vm: vm)

            HStack(alignment: .firstTextBaseline, spacing: .screenInset * 2) {
                AboutColumn()
                    .frame(minWidth: 230)

                VStack {
                    SessionsList()
                    ctas
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

    var ctas: some View {
        HStack(spacing: 15) {
            Spacer()

            Text(vm.alert)
                .font(.headline.weight(.semibold))
                .opacity(vm.showSessionStartAlert ? 1 : 0)
                .animation(.easeIn, value: vm.showSessionStartAlert)
                .accessibilityHidden(vm.showSessionStartAlert == false)

            CTAButton(vm.ctaLabel, action: vm.performCTA)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}
