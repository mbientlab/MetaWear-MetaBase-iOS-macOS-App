// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI
import SwiftUI

struct MigrationSession: View {

    init(importer: MigrateDataPanelVM, vm: MigrationSessionVM)  {
        _importer = .init(wrappedValue: importer)
        _vm =  .init(wrappedValue: vm)
    }
    @StateObject var vm: MigrationSessionVM
    @StateObject var importer: MigrateDataPanelVM

#if os(iOS)
    let minHeight = UIScreen.main.bounds.shortestSide * 0.5
#elseif os(macOS)
    let minHeight = CGFloat(400)
#endif

    var body: some View {
        FocusFlipPanel(
            vm: vm.focus,
            centerColumnNominalWidth: .init(iPhone: .infinity, 450),
            macOSHostWindowPrefix: Windows.migration.tag
        ) { maxWidth in
            ItemsPanel(items: vm.content.debrief, useSmallerSizes: true, maxWidth: maxWidth)
                .frame(minHeight: minHeight)
        } down: { maxWidth in
            MigrationSession.ProgressReportPane(maxWidth: maxWidth)
        } cta: { cta }
        .padding(.top, .init(macOS: 25, iOS: 35))
        .onAppear { if vm.triggerImporter { importer.start() }}
        .onAppear(perform: vm.onAppear)
        .environmentObject(vm)
        .environmentObject(importer)
    }

    @ViewBuilder private var cta: some View {
        if vm.showMigrationCTAs {
            CTAs(
                willStartImport: { vm.focus.setFocus(.importer) },
                skipAction: { vm.focus.setFocus(.complete) },
                successAction: { vm.focus.setFocus(.complete) },
                successCTA: vm.completionCTA
            )
        } else {
            CTAButton(vm.completionCTA, padding: 6, action: { vm.focus.setFocus(.complete) })
        }
    }
}

// MARK: - Components

extension MigrationSession {

    struct ProgressReportPane: View {
        var maxWidth: CGFloat
        var body: some View {
            VStack(alignment: .center, spacing: 45) {
                MigrationSession.ProgressReport()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(40)
            .background(ItemsPanel.PanelBG())
            .padding(10)
            .frame(maxWidth: maxWidth, maxHeight: .infinity, alignment: .leading)
        }
    }

    struct CTAs: View {

        let padding: CGFloat = 6
        let willStartImport: () -> Void
        let skipAction: () -> Void
        let successAction: () -> Void
        let successCTA: String

        @EnvironmentObject private var vm: MigrateDataPanelVM

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
                    idiom.is_Mac ? "Migrate Local Data  􀆊" :
                       (idiom == .iPhone ? "Migrate" : "Migrate Local Data"),
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

        @EnvironmentObject private var vm: MigrateDataPanelVM
        @Namespace private var namespace
        @Environment(\.colorScheme) private var colorScheme

        var body: some View {
            VStack(spacing: 30) {
                stateIcon

                Text(vm.sessionsImportedLabel)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundColor(colorScheme == .light ? .mySecondary : .myTertiary)

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
            .adaptiveFont(.deviceCellTitle)
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
