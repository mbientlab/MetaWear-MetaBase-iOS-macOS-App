// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import SwiftUI
import mbientSwiftUI
import Combine
import MetaWear
import Metadata

extension ActionScreen {

    struct ProgrammingState: View {

        @EnvironmentObject private var action: ActionVM
        @ObservedObject var vm: AboutDeviceVM

        var body: some View {
            ZStack {
                switch action.state[vm.meta.mac]! {
                    case .notStarted: notStartedIndicator
                    case .working: workingIndicator
                    case .completed: completedIndicator
                    case .timeout: failureIndicator
                    case .error: failureIndicator
                }
            }
            .frame(width: 16, height: 16)
        }

        var notStartedIndicator: some View {
            Circle()
                .strokeBorder(lineWidth: 2)
                .foregroundColor(.secondary.opacity(0.8))
        }

        var workingIndicator: some View {
            ProgressView()
                .progressViewStyle(.circular)
                .scaledToFit()
            #if os(macOS)
                .controlSize(.small)
            #endif
        }

        var completedIndicator: some View {
            SFSymbol.checkFilled.image()
                .resizable()
                .scaledToFit()
                .font(.title.weight(.semibold))
                .foregroundColor(.green)
        }

        var failureIndicator: some View {
            SFSymbol.error.image()
                .resizable()
                .scaledToFit()
                .font(.title.weight(.semibold))
                .foregroundColor(.yellow)
        }
    }

    struct ProgressSummary: View {

        @EnvironmentObject private var action: ActionVM
        @ObservedObject var vm: AboutDeviceVM

        var body: some View {
            ZStack {
                switch action.state[vm.meta.mac]! {
                    case .notStarted: notStartedIndicator
                    case .working: workingIndicator
                    case .completed: completedIndicator
                    case .timeout: timeoutIndicator
                    case .error: failureIndicator
                }
            }
            .font(.body.weight(.medium))
        }

        var notStartedIndicator: some View {
           EmptyView()
        }

        @ViewBuilder var workingIndicator: some View {
            if action.actionType == .stream, case .working = action.state[vm.meta.mac] {
                highRefreshWorkingIndicator
            } else {
                Text(action.actionType.workingLabel)
            }
        }

        @ViewBuilder var highRefreshWorkingIndicator: some View {
            if #available(iOS 15.0, macOS 12.0, *) {
                TimelineView(.periodic(from: Date(), by: 3)) { context in
                    Text(action.actionType.workingLabel + " \(action.streamCounters.counts[vm.meta.mac]?.info ?? "")")
                }
            } else {
                Text(action.actionType.workingLabel + " \(action.streamCounters.counts[vm.meta.mac]?.info ?? "")")
            }
        }

        var completedIndicator: some View {
            Text(action.actionType.completedLabel)
                .padding(.horizontal)
                .padding(.vertical, 5)
                .foregroundColor(.accentColor)
                .background(Capsule().foregroundColor(.green))
        }

        var failureIndicator: some View {
            HStack {
                Text("Error")
                refresh
            }
                .padding(.horizontal)
                .padding(.vertical, 3)
                .foregroundColor(.accentColor)
                .background(Capsule().foregroundColor(.pink))
        }

        var timeoutIndicator: some View {
            HStack {
                Text("Unable to find MetaWear nearby")
                refresh
            }
                .padding(.horizontal)
                .padding(.vertical, 3)
                .foregroundColor(.accentColor)
                .background(Capsule().foregroundColor(.yellow))
        }

        var refresh: some View {
            RefreshButton(help: "Retry", didTap: { action.retry(vm.meta) })
                .buttonStyle(.borderless)
        }
    }
}
