// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import SwiftUI
import mbientSwiftUI
import Combine
import MetaWear
import Metadata

extension ActionScreen {

    struct CTAs: View {

        @EnvironmentObject private var vm: ActionLogVM

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
            Button("Download") { }
        }

        private var cancel: some View {
            Button("Cancel") { }
        }

        private var others: some View {
            Button("Others") { }
        }
    }
}
