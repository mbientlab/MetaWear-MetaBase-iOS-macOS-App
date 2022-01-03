// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI
import Combine
import MetaWear
import MetaWearSync

extension ActionScreen {

    struct ProgrammingStateIcon: View {

        @EnvironmentObject private var action: ActionVM
        @ObservedObject var vm: AboutDeviceVM
        var invertTextColor: Bool

        var body: some View {
            ZStack {
                switch action.actionState[vm.meta.mac]! {
                    case .notStarted: notStartedIndicator
                    case .working: workingIndicator
                    case .completed: completedIndicator
                    case .timeout: failureIndicator
                    case .error: failureIndicator
                }
            }
            .frame(width: 16, height: 16)
        }

        private var notStartedIndicator: some View {
            Circle()
                .strokeBorder(lineWidth: 2)
                .foregroundColor(invertTextColor ? .myBackground.opacity(0.5) : .myTertiary)
        }

        private var workingIndicator: some View {
            ProgressView()
                .progressViewStyle(.circular)
                .scaledToFit()
                .colorMultiply(invertTextColor ? .myBackground : .myPrimary)
            #if os(macOS)
                .controlSize(.small)
            #endif
        }

        private var completedIndicator: some View {
            SFSymbol.checkFilled.image()
                .resizable()
                .scaledToFit()
                .font(.title.weight(.semibold))
                .foregroundColor(invertTextColor ? .myBackground : .mySuccess)
        }

        @ViewBuilder private var failureIndicator: some View {
            if case let .error(message) = action.actionState[vm.meta.mac]! {
                WarningPopover(message: message, color: invertTextColor ? .myBackground : .myFailure)
                    .font(.title.weight(.semibold))
            }
        }
    }

    struct ProgressSummaryLabel: View {

        @EnvironmentObject private var action: ActionVM
        @ObservedObject var vm: AboutDeviceVM
        var invertTextColor: Bool

        var body: some View {
            ZStack {
                switch action.actionState[vm.meta.mac]! {
                    case .notStarted: notStartedIndicator
                    case .working: progressReport
                    case .completed: completedIndicator
                    case .timeout: timeoutIndicator
                    case .error: failureIndicator
                }
            }
            .font(.title3.weight(.medium))
        }

        private var notStartedIndicator: some View { EmptyView() }

        private var completedIndicator: some View {
            Text(action.actionType.completedLabel)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(1)
                .padding(.vertical, 5)
                .foregroundColor(invertTextColor ? .myBackground : .mySuccess)
        }

        private var failureIndicator: some View {
            HStack {
                Text("Error")
                    .fontWeight(.semibold)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(1)
                refresh
            }
                .padding(.vertical, 3)
                .foregroundColor(invertTextColor ? .myBackground : .myFailure)
        }

        private var timeoutIndicator: some View {
            HStack(spacing: 20) {
                Text("Not Found")
                    .fontWeight(.semibold)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(1)
                refresh
            }
                .padding(.vertical, 3)
                .foregroundColor(invertTextColor ? .myBackground : .myHighlight)
        }

        private var refresh: some View {
            RefreshButton(help: "Retry", didTap: { action.retry(vm.meta) })
                .buttonStyle(HoverButtonStyle())
        }

        // MARK: - Progress

        private var progressReport: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text(action.actionType.workingLabel)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(1)

                if action.actionType == .stream,
                   case .working = action.actionState[vm.meta.mac],
                   action.streamCounters.counts[vm.meta.mac]?.info != "0" {

                    if #available(iOS 15.0, macOS 12.0, *) {
                        TimelineView(.periodic(from: Date(), by: 2)) { _ in stats }
                    } else { stats }

                } else if action.actionType == .downloadLogs {

                    if #available(iOS 15.0, macOS 12.0, *) {
                        TimelineView(.periodic(from: Date(), by: 2)) { _ in downloadPercent }
                    } else { downloadPercent }
                }
            }
            .animation(.easeOut, value: action.streamCounters.counts[vm.meta.mac]?.info)
        }

        private var stats: some View {
            let streamDatapointCount: String = {
                if let count = action.streamCounters.counts[vm.meta.mac]?.info {
                    return " " + count + " data points"
                } else { return "" }
            }()
            return Text(streamDatapointCount)
                .foregroundColor(invertTextColor ? .myBackground.opacity(0.7) : .mySecondary)
                .font(.subheadline)
        }

        @ViewBuilder private var downloadPercent: some View {
            if case let .working(percent) = action.actionState[vm.info.mac] {
                let label = String(percent) + "%"

                ProgressView(
                    value: Double(percent),
                    total: 100,
                    label: { },
                    currentValueLabel: { }
                )
                    .progressViewStyle(LinearProgressViewStyle(tint: .myBackground))
                    .accessibilityValue(Text(label))
                    .help(label)
                    .frame(width: 100)
            }
        }
    }
}
