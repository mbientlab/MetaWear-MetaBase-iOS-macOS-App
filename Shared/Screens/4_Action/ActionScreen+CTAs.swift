// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI
import Combine
import MetaWear
import MetaWearSync

extension ActionScreen {

    struct CTAs: View {

        @EnvironmentObject private var vm: ActionVM

        var body: some View {
            HStack {
                CloudSaveStateIndicator(state: vm.cloudSaveState)
                Spacer()

                if vm.actionDidComplete || vm.actionType == .stream {
                    successCTAs
                } else {
                    Button("Cancel") { vm.cancelAndUndo() }
                }
            }
            .frame(maxWidth: .infinity)
            .animation(.easeOut, value: vm.actionDidComplete)
            #if os(macOS)
            .controlSize(.large)
            #endif
        }

        @ViewBuilder private var successCTAs: some View {
            switch vm.actionType {
                case .log: Button("Download") { vm.downloadLogs() }
                case .downloadLogs: EmptyView()
                case .stream: Button("Stop Streaming") { vm.stopStreaming() }
            }
            exportFiles
        }

        @ViewBuilder private var exportFiles: some View {
            if vm.showExportFilesCTA {
                Button("Export CSVs") { vm.exportFiles() }
            }
        }

        private var others: some View {
            Button("Other Devices") { vm.backToChooseDevices() }
        }
    }
}

struct CloudSaveStateIndicator: View {

    let state: CloudSaveState
    @State private var animateCloud = false

    var body: some View {
        ZStack {
            switch state {
                case .notStarted: EmptyView()
                case .saving:
                    Label(title: { Text("Saving to iCloud") }) {
                        SFSymbol.icloud.image()
                            .opacity(animateCloud ? 1 : 0.75)
                    }
                    .animation(.easeOut.repeatForever(autoreverses: true), value: animateCloud)
                    .onAppear { animateCloud.toggle() }

                case .saved:
                    Label(title: { Text("Saved") }) { SFSymbol.icloud.image() }
                case .error(let error): WarningPopover(message: error.localizedDescription)
            }
        }
        .animation(.easeOut, value: state)
    }
}
