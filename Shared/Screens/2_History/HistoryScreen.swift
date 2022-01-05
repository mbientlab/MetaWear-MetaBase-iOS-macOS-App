// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Combine
import mbientSwiftUI
import MetaWear
import MetaWearSync

struct HistoryScreen: View {

    @EnvironmentObject private var factory: UIFactory
    @StateObject var vm: HistoryScreenVM

    init(_ factory: UIFactory) {
        _vm = .init(wrappedValue: factory.makeHistoryScreenVM())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Header(vm: vm)
                .keyboardShortcut(.cancelAction)

            HStack(alignment: .firstTextBaseline, spacing: .screenInset * 1.25) {
                AboutColumn()
                    .frame(minWidth: 230)

                VStack {
                    SessionsList(factory)
                    ctas.padding(.top, .screenInset / 2)
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
        HStack(spacing: 35) {
            Spacer()

            Text(vm.alert)
                .font(.headline.weight(.semibold))
                .opacity(vm.showSessionStartAlert ? 1 : 0)
                .animation(.easeIn, value: vm.showSessionStartAlert)
                .accessibilityHidden(vm.showSessionStartAlert == false)

            CTAButton(vm.cta.label, .add , action: vm.performCTA)
                .keyboardShortcut(.defaultAction)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}
