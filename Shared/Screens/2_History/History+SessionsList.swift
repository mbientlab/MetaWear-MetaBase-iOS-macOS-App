// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI
import SwiftUI

extension HistoryScreen {

    struct SessionsList: View {

        @EnvironmentObject private var vm: HistoryScreenVM

        var body: some View {
            VStack {
                Subhead(label: "Prior Sessions")

                List {
                    ForEach(vm.sessions) { session in
                        Row(name: session.name,
                            downloadAction: { vm.download(session: session) })
                    }
                }
                .listStyle(.inset)
            }
        }
    }
}

extension HistoryScreen.SessionsList {

    struct Row: View {

        let name: String
        let downloadAction: (() -> Void)?

        var body: some View {
            HStack {
                Text(name)
                    .font(.body)
                Spacer()
                downloadButton
            }
        }

        @ViewBuilder var downloadButton: some View {
            if let action = downloadAction {
                Button(action: action) {
                    SFSymbol.download.image()
                }
                .buttonStyle(.borderless)
            } else {
                Button(action: {}) {
                    SFSymbol.icloud.image()
                }
                .buttonStyle(.borderless)
            }
        }
    }
}
