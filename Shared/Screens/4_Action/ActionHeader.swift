// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI
import SwiftUI

public protocol ActionHeaderVM {
    var actionType: ActionType { get }
    var representativeConfig: ModulesConfiguration { get }
    var name: String { get }
    func backToHistory()
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
                    .font(.largeTitle)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)

                Text(vm.name)
                    .font(.title2)
                    .foregroundColor(.mySecondary)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, .screenInset)
    }
}
