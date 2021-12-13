// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import SwiftUI
import mbientSwiftUI

extension HistoryScreen {

    struct SessionsList: View {

        var body: some View {
            VStack {
                Subhead(label: "Prior Sessions")

                List {
                    rows
                }
                .listStyle(.inset)
            }
        }

        private var rows: some View {
            ForEach(0..<4) { row in
                Row(name: "\(row)",
                    downloadAction: row == 0 ? nil : { download(name: row) })
            }
        }

        func download(name: Int) {

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
            }
        }
    }
}
