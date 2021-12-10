// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import SwiftUI
import mbientSwiftUI
import Combine
import MetaWear
import Metadata

extension ActionScreen {

    struct ProgrammingState: View {

        @EnvironmentObject private var action: ActionLogVM
        @ObservedObject var vm: AboutDeviceVM

        var body: some View {
            ZStack {
                switch action.programmingState[vm.meta.mac]! {
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
                .controlSize(.small)
                .scaledToFit()
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

        @EnvironmentObject private var action: ActionLogVM
        @ObservedObject var vm: AboutDeviceVM

        var body: some View {
            ZStack {
                switch action.programmingState[vm.meta.mac]! {
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

        var workingIndicator: some View {
            Text("Programming")
        }

        var completedIndicator: some View {
            Text("Logging")
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
