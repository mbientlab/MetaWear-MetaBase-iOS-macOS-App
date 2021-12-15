// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import SwiftUI

struct ProgressSpinner: View {

    var body: some View {
        ProgressView()
            .progressViewStyle(.circular)
            #if os(macOS)
            .controlSize(.small)
            #endif
    }
}
