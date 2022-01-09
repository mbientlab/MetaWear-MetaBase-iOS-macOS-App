// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI

struct CloudSaveStateIndicator: View {

    let state: CloudSaveState
    var showSuccess: Bool = true
    @State private var animateCloud = false
    @Namespace private var namespace

    var body: some View {
        ZStack {
            switch state {
                case .notStarted: EmptyView()
                case .saving: saving
                case .saved: saved
                case .error(let error): WarningPopover(message: error.localizedDescription)
            }
        }
        .adaptiveFont(.ctaAlert)
        .animation(.easeOut, value: state)
    }

    private var saving: some View {
        VStack {
            SFSymbol.icloud.image()
                .adaptiveFont(.ctaAlert)
                .padding(.bottom, 5)
                .matchedGeometryEffect(id: "icloud", in: namespace)
                .opacity(animateCloud ? 1 : 0.75)

            Text("Saving to iCloud...")
                .adaptiveFont(.actionStateDetail)
        }
        .animation(.easeOut.repeatForever(autoreverses: true), value: animateCloud)
        .onAppear { animateCloud.toggle() }
    }

    private var saved: some View {
        SFSymbol.icloudSaved.image()
            .adaptiveFont(.ctaAlert)
            .matchedGeometryEffect(id: "icloud", in: namespace)
            .help("Saved to iCloud")
            .opacity(showSuccess ? 1 : 0)
    }
}
