// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import SwiftUI
import mbientSwiftUI
import Combine
import MetaWear
import MetaWearMetadata

extension ActionScreen {

    struct CTAs: View {

        @EnvironmentObject private var vm: ActionVM

        var body: some View {
            HStack {
                if vm.showSuccessCTAs || vm.actionType == .stream {
                    successCTAs
                } else {
                    cancel
                }
            }
            .animation(.easeOut, value: vm.showSuccessCTAs)
        }

        @ViewBuilder private var successCTAs: some View {
            switch vm.actionType {
                case .log: download
                case .downloadLogs: exportFiles
                case .stream: stopStreaming
            }
        }

        private var exportFiles: some View {
            Button("Export CSVs") { vm.exportFiles() }
        }

        private var download: some View {
            Button("Download") { vm.downloadLogs() }
        }

        private var cancel: some View {
            Button("Cancel") { vm.cancelAndUndo() }
        }

        private var others: some View {
            Button("Other Devices") { vm.goToChooseDevicesScreen() }
        }

        private var stopStreaming: some View {
            Button("Stop & Export CSVs") { vm.stopStreaming() }
        }
    }
}
