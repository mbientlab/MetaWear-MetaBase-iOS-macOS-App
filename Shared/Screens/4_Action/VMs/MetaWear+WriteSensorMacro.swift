// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import MetaWear
import Combine

public extension AnyPublisher where Output == MetaWear {

    func macro(_ config: SensorConfigContainer) -> MWPublisher<MWMacroIdentifier> {
        self.macro(executeOnBoot: true) { metawear in
            metawear
                .optionallyLog(config.accelerometer)
                .optionallyLog(config.altitude)
//                .optionallyLog(config.color)
                .optionallyLog(config.gyroscope)
//                .optionallyLog(config.humidity)
//                .optionallyLog(config.ambientLight)
                .optionallyLog(config.magnetometer)
//                .optionallyLog(config.pressure)
//                .optionallyLog(config.proximity)
//                .optionallyLog(config.thermometer)
                .optionallyLog(config.fusionEuler)
                .optionallyLog(config.fusionGravity)
                .optionallyLog(config.fusionLinear)
                .optionallyLog(config.fusionQuaternion)
        }
        
    }


}
