// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI

public protocol ActionHeaderVM: HeaderVM {
    var actionType: ActionType { get }
    var representativeConfig: ModulesConfiguration { get }
    var title: String { get }
    func backToHistory()
}

public extension ActionHeaderVM {
    var showBackButton: Bool { true }
}

struct ActionHeader: View {

    let vm: ActionHeaderVM

    @Environment(\.presentationMode) private var nav
    @EnvironmentObject private var routing: Routing

    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            HeaderBackButton(overrideBackAction: vm.backToHistory)

            VStack(alignment: .leading, spacing: 12) {
                Text(vm.actionType.title)
                    .adaptiveFont(.screenHeader)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)

                Text(vm.title)
                    .adaptiveFont(.screenHeaderDetail)
                    .foregroundColor(.mySecondary)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Header.Icons(vm: vm)
                .padding(.trailing, .screenInset)
                .offset(y: -.headerMinHeight / 5)
        }
        .padding(.top, 10)
        .frame(maxWidth: .infinity, minHeight: .headerMinHeight, alignment: .topLeading)
        .padding(.top, .headerTopPadding)
        .backgroundToEdges(.myBackground)
        .padding(.bottom, .screenInset)
    }
}
