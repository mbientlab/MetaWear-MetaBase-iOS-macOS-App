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
        @Environment(\.reverseOutColor) private var reverseOut

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
                .foregroundColor(invertTextColor ? reverseOut.opacity(0.5) : .myTertiary)
        }

        private var workingIndicator: some View {
            ProgressView()
                .progressViewStyle(.circular)
                .scaledToFit()
                .colorMultiply(invertTextColor ? reverseOut : .myPrimary)
            #if os(macOS)
                .controlSize(.small)
            #endif
        }

        private var completedIndicator: some View {
            SFSymbol.checkFilled.image()
                .resizable()
                .scaledToFit()
                .adaptiveFont(.actionIcon)
                .foregroundColor(invertTextColor ? reverseOut : .mySuccess)
        }

        @ViewBuilder private var failureIndicator: some View {
            if case let .error(message) = action.actionState[vm.meta.mac]! {
                WarningPopover(message: message, color: invertTextColor ? reverseOut : .myFailure)
                    .adaptiveFont(.actionIcon)
            }
        }
    }

    struct ProgressSummaryLabel: View {

        @EnvironmentObject private var action: ActionVM
        @ObservedObject var vm: AboutDeviceVM
        var invertTextColor: Bool
        @Environment(\.reverseOutColor) private var reverseOut

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
            .adaptiveFont(.actionStateLabel)
        }

        private var notStartedIndicator: some View { EmptyView() }

        private var completedIndicator: some View {
            Text(action.actionType.completedLabel)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(1)
                .padding(.vertical, 5)
                .foregroundColor(invertTextColor ? reverseOut : .mySuccess)
        }

        private var failureIndicator: some View {
            HStack {
                Text("Error")
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(1)
                refresh
            }
                .padding(.vertical, 3)
                .foregroundColor(invertTextColor ? reverseOut : .myFailure)
        }

        private var timeoutIndicator: some View {
            HStack(spacing: 20) {
                Text("Not Found")
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(1)
                refresh
            }
                .padding(.vertical, 3)
                .foregroundColor(invertTextColor ? reverseOut : .myHighlight)
        }

        private var refresh: some View {
            RefreshButton(help: "Retry", didTap: { action.retry(vm.meta) })
                .buttonStyle(HoverButtonStyle())
        }

        // MARK: - Progress

        @ViewBuilder private var progressReport: some View {
            if idiom == .iPhone {
                AccessibilityHStack(vstackAlign: .leading,
                                    vSpacing: 10,
                                    hstackAlign: .firstTextBaseline,
                                    hSpacing: 15) {
                    progressReportContent
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    progressReportContent
                }.animation(.easeOut, value: action.streamCounters.counts[vm.meta.mac]?.info)
            }
        }

        @ViewBuilder private var progressReportContent: some View {
            Text(action.actionType.workingLabel)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(1)

            if action.actionType == .stream,
               case let .working(dataPoints) = action.streamCounters.counts[vm.meta.mac],
                dataPoints > 0 {

                DataPointCounter(mac: vm.meta.mac,
                                 invertTextColor: invertTextColor,
                                 counters: action.streamCounters)

            } else if action.actionType == .downloadLogs {

                DownloadPercentBar(mac: vm.info.mac)
            }
        }


    }
}

struct DataPointCounter: View {

    let mac: MACAddress
    var invertTextColor: Bool
    @ObservedObject var counters: StreamingCountersContainer
    @Environment(\.reverseOutColor) private var reverseOut

    var body: some View {
        if #available(iOS 15.0, macOS 12.0, *) {
            TimelineView(.periodic(from: Date(), by: 1)) { _ in stats }
        } else { stats }
    }

    private var stats: some View {
        let streamDatapointCount: String = {
            if let count = counters.counts[mac]?.info {
                return " " + count + " data points"
            } else { return "" }
        }()
        return Text(streamDatapointCount)
            .foregroundColor(invertTextColor ? reverseOut.opacity(0.7) : .mySecondary)
            .adaptiveFont(.actionStateDetail)
    }
}

struct DownloadPercentBar: View {

    var mac: MACAddress
    @EnvironmentObject private var action: ActionVM
    @Environment(\.reverseOutColor) private var reverseOut

    var body: some View {
        if #available(iOS 15.0, macOS 12.0, *) {
            TimelineView(.periodic(from: Date(), by: 1)) { _ in downloadPercent }
        } else { downloadPercent }
    }

    @ViewBuilder private var downloadPercent: some View {
        if case let .working(percent) = action.actionState[mac] {
            let label = String(percent) + "%"

            ProgressView(
                value: Double(percent),
                total: 100,
                label: { },
                currentValueLabel: { }
            )
                .progressViewStyle(LinearProgressViewStyle(tint: reverseOut))
                .accessibilityValue(Text(label))
                .help(label)
                .frame(width: 100)
        }
    }
}
