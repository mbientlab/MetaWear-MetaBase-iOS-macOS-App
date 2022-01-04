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
                case .saving:
                    VStack {
                        SFSymbol.icloud.image()
                            .font(.title2.weight(.bold))
                            .padding(.bottom, 5)
                            .matchedGeometryEffect(id: "icloud", in: namespace)
                            .opacity(animateCloud ? 1 : 0.75)

                        Text("Saving to iCloud...")
                            .font(.callout)
                    }
                    .animation(.easeOut.repeatForever(autoreverses: true), value: animateCloud)
                    .onAppear { animateCloud.toggle() }

                case .saved:
                    SFSymbol.icloudSaved.image()
                        .font(.title2.weight(.bold))
                        .matchedGeometryEffect(id: "icloud", in: namespace)
                        .help("Saved to iCloud")
                        .opacity(showSuccess ? 1 : 0)

                case .error(let error): WarningPopover(message: error.localizedDescription)
            }
        }
        .font(.headline)
        .animation(.easeOut, value: state)
    }
}
