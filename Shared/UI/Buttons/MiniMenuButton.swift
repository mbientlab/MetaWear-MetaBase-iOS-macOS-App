// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import SwiftUI
import mbientSwiftUI

struct MiniMenuButton<Content: View>: View {

    let content: () -> Content

    init(@ViewBuilder _ menu: @escaping () -> Content) {
        self.content = menu
    }

#if os(macOS)
    var body: some View {
        if #available(macOS 12.0, *) {
            Menu(content: content, label: { label })
            .fixedSize()
            .menuIndicator(.hidden)
            .menuStyle(.borderlessButton)
        } else {
            Menu(content: content, label: { label })
            .fixedSize()
            .menuStyle(.borderlessButton)
        }
    }
#endif

#if os(iOS)
    var body: some View {
        if #available(iOS 15.0, *) {
            Menu(content: content, label: { label })
            .fixedSize()
            .menuIndicator(.hidden)
            .menuStyle(.borderlessButton)
        } else {
            Menu(content: content, label: { label })
            .fixedSize()
            .menuStyle(.borderlessButton)
        }
    }
#endif

    var label: some View {
        SFSymbol.moreMenu.image()
            .font(.headline)
            .foregroundColor(.secondary)
    }
}
