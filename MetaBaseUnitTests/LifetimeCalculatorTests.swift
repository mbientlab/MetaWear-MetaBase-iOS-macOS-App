// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import XCTest
@testable import MetaBase
import MetaWear

class LifetimeCalculatorTests: XCTestCase {

    func test_NoSetting() {
        let config: UserSensorConfiguration = .init()
        let models: [MetaWear.Model] = [.motionRL]
        let modules = makeMockRLModules()

        let sut: MWLifetimeCalculator = .init(config: config, models: models, modules: modules)

        XCTAssertEqual(sut.logLife, 0)
        XCTAssertEqual(sut.batteryLife, 0)
    }

    func test_GyroscopeSlowRL() {
        var config: UserSensorConfiguration = .init()
        config.enableGyroscope()
        config.gyroscopeRate = .hz25

        let models: [MetaWear.Model] = [.motionRL]
        let modules = makeMockRLModules()

        let sut: MWLifetimeCalculator = .init(config: config, models: models, modules: modules)

        XCTAssertEqual(sut.logLife, 20700.0)
        XCTAssertEqual(sut.batteryLife, 720000.0)
    }

    func test_GyroscopeFastRL() {
        var config: UserSensorConfiguration = .init()
        config.enableGyroscope()
        config.gyroscopeRate = .hz1600

        let models: [MetaWear.Model] = [.motionRL]
        let modules = makeMockRLModules()

        let sut: MWLifetimeCalculator = .init(config: config, models: models, modules: modules)

        XCTAssertEqual(sut.logLife, 300.0)
        XCTAssertEqual(sut.batteryLife, 720000.0)
    }

    func test_SensorFusionRL() {
        var config: UserSensorConfiguration = .init()
        config.enableSensorFusion()

        let models: [MetaWear.Model] = [.motionRL]
        let modules = makeMockRLModules()

        let sut: MWLifetimeCalculator = .init(config: config, models: models, modules: modules)

        XCTAssertEqual(sut.logLife, 3300)
        XCTAssertEqual(sut.batteryLife, 388800)
    }
}

extension LifetimeCalculatorTests {

    func makeMockRLModules() -> [[MWModules]]  {
        [[
            .barometer(.bme280),
            .gyroscope(.bmi270),
            .magnetometer,
            .sensorFusion,
        ]]
    }
}
