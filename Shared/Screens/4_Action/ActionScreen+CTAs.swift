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
                
                Spacer()

                CloudSaveStateIndicator(state: vm.cloudSaveState, showSuccess: false)
                    .padding(.trailing, 75)

                if vm.actionDidComplete {
                    successCTAs
                } else if vm.actionType == .stream {
                    CTAButton("Stop Streaming") { vm.stopStreaming() }
                } else if vm.actionType == .downloadLogs {
                    pauseDownloadCTA
                } else {
                    cancelCTA
                }
            }
            .frame(maxWidth: .infinity)
            .animation(.easeOut, value: vm.actionDidComplete)
#if os(macOS)
            .controlSize(.large)
#endif
        }

        private var cancelCTA: some View {
            CTAButton("Cancel", hover: .mySecondary, base: .mySecondary) { vm.cancelAndUndo() }
        }

        private var pauseDownloadCTA: some View {
            CTAButton("Stop", hover: .mySecondary, base: .mySecondary) { vm.pauseDownload() }
        }

        @ViewBuilder private var successCTAs: some View {
            switch vm.actionType {
                case .log: CTAButton("Download", .download) { vm.downloadLogs() }
                case .downloadLogs: exportFiles
                case .stream: exportFiles
            }
        }

        @ViewBuilder private var exportFiles: some View {
            if vm.showExportFilesCTA {
                CTAButton("Export CSVs") { vm.exportFiles() }
#if os(iOS)
                .background(export)
#endif
            }
        }

#if os(iOS)
        @ViewBuilder var export: some View {
            if let export = vm.export {
                UIActivityPopover(items: [export], didDismiss: vm.didDismissExportPopover)
            }
        }
#endif
    }
}
