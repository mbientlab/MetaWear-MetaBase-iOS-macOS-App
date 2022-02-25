// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import SwiftUI

struct DownloadAlert {
    static func alert(stop: @escaping () -> Void) -> Alert {
        Alert(
            title: Text("Do you want to download later?"),
            message: Text("While you can resume this download later, some data points may be lost during cancellation."),
            primaryButton: .cancel(Text("Keep Downloading")),
            secondaryButton: .destructive(Text("Stop"), action: stop)
        )
    }
}
