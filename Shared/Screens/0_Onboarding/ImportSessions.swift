// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI

struct ImportSessions {
    private init() { }
}

extension ImportSessions {

    struct CTAs: View {

        let padding: CGFloat = 6
        let willStartImport: () -> Void
        let skipAction: () -> Void
        let successAction: () -> Void
        let successCTA: String

        @EnvironmentObject private var vm: ImportSessionsVM

        var body: some View {
            ZStack {
                switch vm.isImporting {
                    case .notStarted: notStartedCTAs
                    case .completed: completedCTA
                    case .importing: completedCTA.hidden()
                }
            }.animation(.easeInOut, value: vm.isImporting)
        }

        private var notStartedCTAs: some View {
            HStack(spacing: 30) {
                CTAButton(
                    "Later",
                    hover: .mySecondary,
                    base: .myTertiary,
                    padding: padding,
                    action: skipAction
                )
                CTAButton(
                    "Migrate Local Data  􀆊",
                    padding: padding,
                    action: {
                        willStartImport()
                        vm.start()
                    }
                )
            }
        }

        private var completedCTA: some View {
            CTAButton(
                successCTA,
                padding: padding,
                action: successAction
            )
        }
    }

    struct ProgressReport: View {

        let padding: CGFloat = 6

        @EnvironmentObject private var vm: ImportSessionsVM
        @Namespace private var namespace

        var body: some View {
            VStack(spacing: 30) {
                stateIcon

                Text(vm.sessionsImportedLabel)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundColor(.myTertiary)

                if vm.isImporting == .completed,
                    let error = vm.error {
                    Text(error.localizedDescription)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("\n\n")
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .hidden()
                }
            }
            .adaptiveFont(.primaryActionText)
            .lineSpacing(9)
            .multilineTextAlignment(.center)
        }

        private var stateIcon: some View {
            ZStack {
                switch vm.isImporting {
                    case .importing:
                        ProgressSpinnerCircleOutline()
                            .matchedGeometryEffect(id: "state", in: namespace)

                    case .notStarted:
                        EmptyView()

                    case .completed:
                        completedSymbol.image()
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.mySuccess)
                            .matchedGeometryEffect(id: "state", in: namespace)
                }
            }
                .frame(width: 60, height: 60)
                .animation(.easeOut, value: vm.isImporting)
        }

        private var completedSymbol: SFSymbol {
            guard let error = vm.error,
                    error != .alreadyImportedDataFromThisDevice
            else { return .checkFilled }
            return .error
        }
    }
}
