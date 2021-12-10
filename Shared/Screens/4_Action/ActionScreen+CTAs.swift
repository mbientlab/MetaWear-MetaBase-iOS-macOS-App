// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import SwiftUI
import mbientSwiftUI
import Combine
import MetaWear
import Metadata

extension ActionScreen {

    struct CTAs: View {

        @EnvironmentObject private var vm: ActionVM

        var body: some View {
            HStack {
                if vm.showSuccessCTAs {
                    others
                    download
                } else {
                    cancel
                }
            }
            .animation(.easeOut, value: vm.showSuccessCTAs)
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
    }
}
