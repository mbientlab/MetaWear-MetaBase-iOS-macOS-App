//
//  Helpers.swift
//  MetaBase
//
//  Created by Stephen Schiffli on 10/24/17.
//  Copyright © 2017 MBIENTLAB, INC. All rights reserved.
//

import XCTest
import Parse
import Bolts
import CoreBluetooth
@testable import MetaWear
@testable import MetaWearCpp
#if TRACKER
    @testable import MetaTracker
#else
    @testable import MetaBase
#endif


extension MetaWear {
     func accelData(count: Int, startingTime: Date = Date()) -> State {
        let state = State(sensor: SensorConfig.accelerometerBMI160, device: self, isStreaming: false)
        let epoch = Int64(Date().timeIntervalSince1970 * 1000.0)
        var sample: [Float] = [8.98, 7.98, 6.98]
        var data = MblMwData(epoch: epoch, extra: nil, value: &sample, type_id: MBL_MW_DT_ID_CARTESIAN_FLOAT, length: 12)
        for _ in 1...count { state.handler(bridge(obj: state), &data) }
        state.finishCsvFile(startingTime)
        return state
    }
    func temperatureData(count: Int, startingTime: Date = Date()) -> State {
        let state = State(sensor: SensorConfig.temperature, device: self, isStreaming: false)
        let epoch = Int64(startingTime.timeIntervalSince1970 * 1000.0)
        var sample: Float = 26.25
        var data = MblMwData(epoch: epoch, extra: nil, value: &sample, type_id: MBL_MW_DT_ID_FLOAT, length: 4)
        for _ in 1...count { state.handler(bridge(obj: state), &data) }
        state.finishCsvFile(startingTime)
        return state
    }
}

//extension Sensor {
    //    static func accelData(count: Int) -> Sensor {
    //        let data = [MBLAccelerometerData](repeating:MBLAccelerometerData(x: 8.98, y: 7.98, z: 6.98, timestamp: Date(), data: Data()), count: count)
    //        let sensor = AccelerometerBMI160.config.sensor
    //        sensor.capturedData = data
    //        return sensor
    //    }
    //    static func gyroData(count: Int) -> Sensor {
    //        let data = [MBLGyroData](repeating:MBLGyroData(x: 8.98, y: 7.98, z: 6.98, timestamp: Date(), data: Data()), count: count)
    //        let sensor = Gyroscope.config.sensor
    //        sensor.capturedData = data
    //        return sensor
    //    }
    //    static func quaternionData(count: Int) -> CapturedData {
    //        let data = [MBLQuaternionData](repeating:MBLQuaternionData(w: 8.98, x: 8.98, y: 8.98, z: 8.98, timestamp: Date()), count: count)
    //        return CapturedData(sensor: Quaternion(), array: data, metadata: DeviceMetaData.test)
    //    }
    //    static func eulerData(count: Int) -> CapturedData {
    //        let data = [MBLEulerAngleData](repeating:MBLEulerAngleData(h: 8.98, p: 8.98, r: 8.98, y: 8.98, timestamp: Date()), count: count)
    //        return CapturedData(sensor: EulerAngle(), array: data, metadata: DeviceMetaData.test)
    //    }
    //    static func temperatureData(count: Int) -> CapturedData {
    //        let data = [MBLNumericData](repeating:MBLNumericData(number: 8.98, timestamp: Date()), count: count)
    //        return CapturedData(sensor: Temperature(), array: data, metadata: DeviceMetaData.test)
    //    }
    //    static func pressureData(count: Int) -> CapturedData {
    //        var data: [MBLNumericData] = []
    //        for _ in 0..<count {
    //            data.append(MBLNumericData(number: NSNumber(value: Double(arc4random()) / 100000.0), timestamp: Date()))
    //        }
    //        return CapturedData(sensor: PressureBMP280(), array: data, metadata: DeviceMetaData.test)
    //    }
    //    static func humidityData(count: Int) -> CapturedData {
    //        let data = [MBLNumericData](repeating:MBLNumericData(number: 8.98, timestamp: Date()), count: count)
    //        return CapturedData(sensor: Humidity(), array: data, metadata: DeviceMetaData.test)
    //    }
    //    static func ambientLightData(count: Int) -> CapturedData {
    //        let data = [MBLNumericData](repeating:MBLNumericData(number: 8.98, timestamp: Date()), count: count)
    //        return CapturedData(sensor: AmbientLight(), array: data, metadata: DeviceMetaData.test)
    //    }
    //    static func proximityData(count: Int) -> CapturedData {
    //        let data = [MBLNumericData](repeating:MBLNumericData(number: 8.98, timestamp: Date()), count: count)
    //        return CapturedData(sensor: Proximity(), array: data, metadata: DeviceMetaData.test)
    //    }
    //    static func colorData(count: Int) -> CapturedData {
    //        let data = [MBLRGBData](repeating:MBLRGBData(red: 898, green: 898, blue: 898, clear: 898, timestamp: Date()), count: count)
    //        return CapturedData(sensor: Color(), array: data, metadata: DeviceMetaData.test)
    //    }
//}

