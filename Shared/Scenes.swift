// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI

struct MainScene {
    // ConfigureScreen showing 3 tiles w/ equal margins (635) + extra width (90)
    static let minWidth: CGFloat = 1100

    // ConfigureScreen showing 2 tile rows (585)
    static let minHeight: CGFloat = 675


}

// MARK: - Extra Window Scenes (macOS)

struct MacOnboardingWindow: View {
    @EnvironmentObject var factory: UIFactory
    var body: some View {
        OnboardingPanel(importer: factory.makeImportVM(),
                        vm: factory.makeOnboardingVM())
            .frame(minWidth: 900, minHeight: MainScene.minHeight)
    }
}


struct MacMigrationWindow: View {
    @EnvironmentObject var factory: UIFactory
    var body: some View {
        MigrateDataPanel(importer: factory.makeImportVM(),
                         vm: factory.makeMigrationVM())
            .frame(minWidth: 900, minHeight: MainScene.minHeight)
    }
}
