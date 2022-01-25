// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI
import MetaWear
import SwiftUI

extension ChooseDevicesScreen {

    struct NoDevicesFound: View {
        static var transitionInterval = Double(1)
        let shouldShowList: Binding<Bool>

        var body: some View {
            GeometryReader {
                Content(frame: $0.frame(in: .local), shouldDisappear: shouldShowList)
            }
        }
    }
}

private extension ChooseDevicesScreen.NoDevicesFound {

    struct Content: View {

        let frame: CGRect
        let shouldDisappear: Binding<Bool>
        @Environment(\.namespace) private var namespace
        @Namespace private var fallbackNamespace
        @Environment(\.colorScheme) private var colorScheme

        // Coordinate an animated disappearance
        @EnvironmentObject private var vm: DiscoveryListVM
        @EnvironmentObject private var onboard: OnboardState
        private var willDisappear: Bool { vm.listIsEmpty == false && onboard.didOnboard }

        // Coordinate the transition animations
        @State private var didAppear = false
        @State private var animate = false

        var body: some View {
            VStack(alignment: .center, spacing: .init(macOS: 0, iOS: 80)) {
                if didAppear {
                    atomAnimation
                    instruction
                    heroImage
                }
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: idiom.is_Mac ? .bottom : .center
            )
            .background(hueGradient)
            .animation(.easeInOut(duration: transitionInterval), value: didAppear)
            .onAppear(perform: startAnimations)
            .onChange(of: willDisappear, perform: startDisappearance)
        }

        private func startAnimations() {
            didAppear.toggle()
            DispatchQueue.main.after(transitionInterval) {
                animate.toggle()
            }
        }

        private func startDisappearance(_ willDisappear: Bool) {
            DispatchQueue.main.after(1.5) {
                didAppear.toggle()
                DispatchQueue.main.after(transitionInterval) {
                    shouldDisappear.wrappedValue = true
                }
            }
        }

        // MARK: - Progress Animation

        private var atomAnimation: some View {
            let removal = AnyTransition.move(edge: .top)
            let insertion = AnyTransition
                .scale
                .animation(.spring(
                    response: 0.2,
                    dampingFraction: 0.5,
                    blendDuration: 1
                ).delay(transitionInterval + 0.15))

            return AtomAnimation(
                animate: animate,
                size: min(180, max(90, frame.size.width * 0.15)),
                color: colorScheme == .light ? .mySuccess : .myPrimaryTinted
            )
            #if os(macOS)
                .matchedGeometryEffect(id: "scanning", in: namespace ?? fallbackNamespace)
            #endif
                .padding(.bottom, 75)
                .transition(.asymmetric(insertion: insertion, removal: removal))
        }

        // MARK: - Instruction

        private var instruction: some View {
            var text: some View {
                Text("Finding nearby MetaWear")
                    .adaptiveFont(.onboardingLargeTitle)
                    .foregroundColor(.myPrimaryTinted)
            }

            let removal = AnyTransition.opacity
            let insertion = removal.animation(.default.delay(transitionInterval))

            return SpotlightShimmerText(
                foreground: text,
                animate: animate,
                travel: frame.size.width
            )
                .transition(.asymmetric(insertion: insertion, removal: removal))
        }

        // MARK: - Hero
        private var heroImage: some View {
            let removal = AnyTransition
                .move(edge: .bottom)

            let insertion = removal
                .combined(with: .scale(scale: 20, anchor: .bottom))
                .animation(.spring(
                    response: 0.6,
                    dampingFraction: 0.83,
                    blendDuration: transitionInterval
                ))

            return SharedImages.metawearSide.image()
                .resizable()
                .scaledToFit()
                .alignmentGuide(VerticalAlignment.center) { _ in
                    if idiom == .macOS { return frame.minY }
                    return frame.minY - 50
                }
                .frame(maxWidth: .infinity, maxHeight: 250)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, .screenInset * 2)
                .transition(.asymmetric(insertion: insertion, removal: removal))
        }

        // MARK: - BG
        @Environment(\.reverseOutColor) private var reverseOut
        private var hueGradient: some View {
            Circle()
                .fill(reverseOut)
                .hueRotation(.degrees(-5))
                .blur(radius: 100)
                .offset(y: frame.size.height / 4)
                .transition(.opacity)
            #if os(iOS)
                .edgesIgnoringSafeArea(.all)
            #endif
        }
    }
}

