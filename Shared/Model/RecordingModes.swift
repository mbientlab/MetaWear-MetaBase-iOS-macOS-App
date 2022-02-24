// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI
import MetaWear
import SwiftUI

public enum RecordingModes: String, Selectable {
    case stream, log, remote
    public var displayName: String { rawValue.capitalized }
    public var id: RawValue { rawValue }

    func helpView() -> AnyView? {
        switch self {
        case .stream, .log: return nil
        case .remote: return AnyView(RemoteHelpView())
        }
    }
}

struct RemoteHelpView: View {

    @StateObject private var emulatorLog = MWLED.Flash.Emulator(.solid(), .red)
    @StateObject private var emulatorPause = MWLED.Flash.Emulator(.solid(), .yellow)

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Remote Control Logging")
                .adaptiveFont(.configureTileTitle)
                .foregroundColor(.myHighlight)

            Text("Use the MetaWear's button to start or pause data recording.")
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .adaptiveFont(.configureTileMenu)

            Text("Compared to logging started immediately from MetaBase, this mode saves some battery, minimizes download size, and helps to split sessions into trials.")
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .adaptiveFont(.body)

            Text("Logging starts (or pauses) the moment the button is released. While pressed, the LED's color indicates what will happen on release. Logs will include timestamps for button press and release.")
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .adaptiveFont(.body)

            HStack {
                VStack { log }
                VStack { pause }
            }
        }
        .environment(\.metaWearModel, .motionS)
    }

    private let metaWearSize = CGFloat(100)

    @ViewBuilder private var log: some View {

        Capsuled(text: "Logging", textColor: Color(.systemRed))
            .adaptiveFont(.configureTileMenu)

        MetaWearWithLED(
            width: metaWearSize,
            height: metaWearSize,
            ledEmulator: emulatorLog
        )
            .opacity(0.8)
            .onAppear { emulatorLog.emulate() }
    }

    @Environment(\.colorScheme) private var scheme
    @ViewBuilder private var pause: some View {

        Capsuled(text: "Paused", textColor: Color(.systemYellow))
            .adaptiveFont(.configureTileMenu)

        MetaWearWithLED(
            width: metaWearSize,
            height: metaWearSize,
            ledEmulator: emulatorPause
        )
            .opacity(0.8)
            .onAppear { emulatorPause.emulate() }
    }
}

struct Capsuled: View {

    var text: String
    var textColor: Color

    var body: some View {
        Text(text)
            .foregroundColor(textColor)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(Capsule(style: .continuous).foregroundColor(.black.opacity(0.3)))
    }
}
