// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI

extension HistoryScreen {

    struct CTAs: View {

        @EnvironmentObject private var vm: HistoryScreenVM
        @Environment(\.colorScheme) private var colorScheme
        var layoutVertically: Bool

        var body: some View {
            #if os(macOS)
            horizontalLayout
            #elseif os(iOS)
            if layoutVertically { verticalLayout } else { horizontalLayout }
            #endif
        }

        private var horizontalLayout: some View {
            HStack(spacing: 35) {
                Spacer(minLength: 0)
                alert
                cta
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }

        private var verticalLayout: some View {
            VStack(alignment: .trailing, spacing: 15) {
                if vm.showSessionStartAlert {
                    HStack {
                        SFSymbol.error.image()
                            .adaptiveFont(.ctaMajor.adjustingSize(steps: -1).withWeight(.bold))
                            .foregroundColor(.myHighlight)

                        alert
                            .padding(.horizontal, .screenInset)
                            .padding(.trailing, .screenInset)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else { cta.transition(.move(edge: .bottom).combined(with: .opacity)) }
            }
            .animation(.easeIn, value: vm.showSessionStartAlert)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }

        let iPhoneSuggestion = idiom == .iPhone ? " to start a new session" : ""

        private var alert: some View {
            Text(vm.alert + iPhoneSuggestion)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(2)
                .adaptiveFont(.ctaAlert)
                .foregroundColor(.myHighlight)
                .brightness(colorScheme == .light ? -0.08 : 0)
                .opacity(vm.showSessionStartAlert ? 1 : 0)
                .offset(x: vm.showSessionStartAlert ? 0 : 9)
                .animation(.easeIn, value: vm.showSessionStartAlert)
                .accessibilityHidden(vm.showSessionStartAlert == false)

        }

        private var cta: some View {
            CTAButton(vm.cta.label, .add , action: vm.performCTA)
                .keyboardShortcut(.defaultAction)
                .disabled(!vm.enableCTA)
                .allowsHitTesting(vm.enableCTA)
        }
    }
}