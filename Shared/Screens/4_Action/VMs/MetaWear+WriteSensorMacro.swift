// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import MetaWear
import Combine

public extension AnyPublisher where Output == MetaWear {
    func macro(_ config: ModulesConfiguration) -> MWPublisher<MWMacroIdentifier> {
        self.macro(executeOnBoot: true) { metawear in
            metawear
                .optionallyLog(config.accelerometer)
                .optionallyLog(config.altitude)
                .optionallyLog(config.gyroscope)
                .optionallyLog(byPolling: config.humidity)
                .optionallyLog(config.ambientLight)
                .optionallyLog(config.magnetometer)
                .optionallyLog(config.pressure)
                .optionallyLog(byPolling: config.thermometer)
                .optionallyLog(config.fusionEuler)
                .optionallyLog(config.fusionGravity)
                .optionallyLog(config.fusionLinear)
                .optionallyLog(config.fusionQuaternion)
        }
    }
}
