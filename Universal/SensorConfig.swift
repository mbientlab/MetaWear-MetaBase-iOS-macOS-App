//
//  SensorConfig.swift
//  Refactor
//
//  Created by Stephen Schiffli on 1/3/18.
//  Copyright © 2018 MBIENTLAB, INC. All rights reserved.
//

import UIKit
import MetaWear
import MetaWearCpp
import BoltsSwift


extension DateFormatter {
    convenience init(_ block: @escaping (DateFormatter) -> Void) {
        self.init()
        block(self)
    }
}
fileprivate let zoneFormatter = DateFormatter { $0.dateFormat = "Z" }
fileprivate var csvHeaderRoot: String {
    get {
        return "epoc (ms),timestamp (\(zoneFormatter.string(from: Date()))),elapsed (s),"
    }
}
fileprivate let rawSensors = ["Accelerometer", "Gyroscope", "Magnetometer"]
fileprivate let fusedSensors = ["Euler Angles", "Gravity", "Linear Acceleration", "Quaternion"]

extension MblMwData {
    func values() -> String {
        switch type_id {
        case MBL_MW_DT_ID_UINT32:
            return ""
        case MBL_MW_DT_ID_FLOAT:
            let tmp = valueAs() as Float
            return String(format: "%.3f", tmp)
        case MBL_MW_DT_ID_CARTESIAN_FLOAT:
            let tmp = valueAs() as MblMwCartesianFloat
            return String(format: "%.3f,%.3f,%.3f", tmp.x, tmp.y, tmp.z)
        case MBL_MW_DT_ID_INT32:
            return ""
        case MBL_MW_DT_ID_BYTE_ARRAY:
            return ""
        case MBL_MW_DT_ID_BATTERY_STATE:
            return ""
        case MBL_MW_DT_ID_TCS34725_ADC:
            return ""
        case MBL_MW_DT_ID_EULER_ANGLE:
            let tmp = valueAs() as MblMwEulerAngles
            return String(format: "%.3f,%.3f,%.3f,%.3f", tmp.pitch, tmp.roll, tmp.yaw, tmp.heading)
        case MBL_MW_DT_ID_QUATERNION:
            let tmp = valueAs() as MblMwQuaternion
            return String(format: "%.3f,%.3f,%.3f,%.3f", tmp.w, tmp.x, tmp.y, tmp.z)
        case MBL_MW_DT_ID_CORRECTED_CARTESIAN_FLOAT:
            return ""
        case MBL_MW_DT_ID_OVERFLOW_STATE:
            return ""
        case MBL_MW_DT_ID_SENSOR_ORIENTATION:
            return ""
        default:
            fatalError("unknown data type")
        }
    }
}

extension OutputStream: TextOutputStream {
    public func write(_ string: String) {
        let data = string.data(using: .utf8)!
        let _ = data.withUnsafeBytes { write($0, maxLength: data.count) }
    }
}

class SensorConfig: NSObject {
    typealias ConfigureFn = (OpaquePointer, State) -> Task<()>
    typealias StartFn = (OpaquePointer) -> Void
    typealias SignalFn = (OpaquePointer, State) -> Task<OpaquePointer>
    typealias WriteFn = (MblMwData, State) -> Void
    typealias ExistsFn = (OpaquePointer) -> Bool

    let name: String
    let anonymousEventName: String
    let iconName: String
    let values: [String]
    let frequencyLookup: [Double]
    let samplesPerPacket: Int
    let mask: Int64
    let valueLookup: [Any]
    let exclusiveWith: [String]
    let csvHeader: String
    let rangeValues: [String]?
    let rangeLookup: [Any]?
    
    var configure: ConfigureFn!
    var start: StartFn!
    var signal: SignalFn!
    var writeValue: WriteFn!
    var exists: ExistsFn!
    
    var selectedIdx: Int?
    var selectedRangeIdx: Int?
    
    var packetsPerSecond: Double {
        guard let selectedIdx = selectedIdx else {
            return 0
        }
        return frequencyLookup[selectedIdx] / Double(samplesPerPacket)
    }
    var period: TimeInterval {
        guard let selectedIdx = selectedIdx else {
            return 0
        }
        return 1.0 / frequencyLookup[selectedIdx]
    }
    var selectedValue: Any? {
        guard let selectedIdx = selectedIdx else {
            return nil
        }
        return valueLookup[selectedIdx]
    }
    var selectedRange: Any? {
        guard let selectedRangeIdx = selectedRangeIdx else {
            return nil
        }
        return rangeLookup?[selectedRangeIdx]
    }

    init(name: String, anonymousEventName: String, iconName: String, values: [String],
         frequencyLookup: [Double], valueLookup: [Any], exclusiveWith: [String],
         csvHeader: String, samplesPerPacket: Int = 1, mask: Int64 = 0xffffffff,
         configure: ConfigureFn! = nil, start: StartFn! = nil, signal: SignalFn! = nil,
         exists: ExistsFn! = nil, writeValue: WriteFn! = {$1.csv.write($1.csvRow($0))},
         rangeValues: [String]? = nil, rangeLookup: [Any]? = nil) {
        self.name = name
        self.anonymousEventName = anonymousEventName
        self.iconName = iconName
        self.values = values
        self.frequencyLookup = frequencyLookup
        self.samplesPerPacket = samplesPerPacket
        self.mask = mask
        self.valueLookup = valueLookup
        self.exclusiveWith = exclusiveWith
        self.csvHeader = csvHeaderRoot + csvHeader
        self.rangeValues = rangeValues
        self.rangeLookup = rangeLookup
        self.configure = configure
        self.start = start
        self.signal = signal
        self.writeValue = writeValue
        self.exists = exists
    }
    
    static func Accelerometer(values: [String], frequencyLookup: [Double],
                              valueLookup: [Float], moduleId: UInt8,
                              rangeValues: [String], rangeLookup: [Float]) -> SensorConfig {
        return SensorConfig(
            name: "Accelerometer",
            anonymousEventName: "acceleration",
            iconName: "AccelerometerIcon",
            values: values,
            frequencyLookup: frequencyLookup,
            valueLookup: valueLookup,
            exclusiveWith: fusedSensors,
            csvHeader: "x-axis (g),y-axis (g),z-axis (g)",
            samplesPerPacket: 2,
            configure: { (board, state) in
                mbl_mw_acc_set_range(board, state.sensor.selectedRange.map { $0 as! Float } ?? 16.0)
                mbl_mw_acc_set_odr(board, state.sensor.selectedValue as! Float)
                mbl_mw_acc_write_acceleration_config(board);
                return Task<()>(())
            },
            start: { (board) in
                mbl_mw_acc_enable_acceleration_sampling(board)
                mbl_mw_acc_start(board)
            },
            signal: { (board, state) in
                let signal = mbl_mw_acc_get_acceleration_data_signal(board)!
                guard state.isStreaming else {
                    return Task<OpaquePointer>(signal)
                }
                return signal.packerCreate(count: 2)
            },
            exists: { (board) in
                return mbl_mw_metawearboard_lookup_module(board, MBL_MW_MODULE_ACCELEROMETER) == moduleId
            },
            rangeValues: rangeValues,
            rangeLookup: rangeLookup
        )
    }
    
    static func Pressure(values: [String], frequencyLookup: [Double],
                         valueLookup: [Any], configure: ConfigureFn!,
                         moduleId: UInt8) -> SensorConfig {
        return SensorConfig(
            name: "Pressure",
            anonymousEventName: "pressure",
            iconName: "PressureIcon",
            values: values,
            frequencyLookup: frequencyLookup,
            valueLookup: valueLookup,
            exclusiveWith: [],
            csvHeader: "pressure (Pa)",
            configure: configure,
            start: { (board) in
                mbl_mw_baro_bosch_start(board)
            },
            signal: { (board, state) in
                return Task<OpaquePointer>(mbl_mw_baro_bosch_get_pressure_data_signal(board))
            },
            exists: { (board) in
                return mbl_mw_metawearboard_lookup_module(board, MBL_MW_MODULE_BAROMETER) == moduleId
            }
        )
    }


    
    static func SensorFusion(name: String, anonymousEventName: String, iconName: String,
                             csvHeader: String, type: MblMwSensorFusionData, mask: Int64) -> SensorConfig {
        return SensorConfig(
            name: name,
            anonymousEventName: anonymousEventName,
            iconName: iconName,
            values: ["100 Hz"],
            frequencyLookup: [100.0],
            valueLookup: [],
            exclusiveWith: rawSensors,
            csvHeader: csvHeader,
            mask: mask,
            configure: { (board, state) in
                let magnetometer = mbl_mw_metawearboard_lookup_module(board, MBL_MW_MODULE_MAGNETOMETER) != MBL_MW_MODULE_TYPE_NA
                let mode = magnetometer ? MBL_MW_SENSOR_FUSION_MODE_NDOF : MBL_MW_SENSOR_FUSION_MODE_IMU_PLUS
                mbl_mw_sensor_fusion_set_mode(board, mode)
                mbl_mw_sensor_fusion_set_acc_range(board, MBL_MW_SENSOR_FUSION_ACC_RANGE_16G)
                mbl_mw_sensor_fusion_set_gyro_range(board, MBL_MW_SENSOR_FUSION_GYRO_RANGE_2000DPS)
                mbl_mw_sensor_fusion_write_config(board)
                return Task<()>(())
            },
            start: { (board) in
                mbl_mw_sensor_fusion_enable_data(board, type)
                mbl_mw_sensor_fusion_start(board)
            },
            signal: { (board, state) in
                return Task<OpaquePointer>(mbl_mw_sensor_fusion_get_data_signal(board, type))
            },
            exists: { (board) in
                return mbl_mw_metawearboard_lookup_module(board, MBL_MW_MODULE_SENSOR_FUSION) != MBL_MW_MODULE_TYPE_NA
            }
        )
    }
    
    func combineWith(_ other: SensorConfig) -> SensorConfig {
        if type(of: self) === type(of: other) {
            return self
        }
        if other.name.caseInsensitiveCompare("Accelerometer") == .orderedSame {
            return SensorConfig.accelerometerBMI160
        }
        if other.name.caseInsensitiveCompare("Pressure") == .orderedSame {
            return SensorConfig.pressureBMP280
        }
        return self
    }
    
    func isConfigForAnonymousEventName(_ eventName: String?) -> Bool {
        guard let eventName = eventName else {
            return false
        }
        return eventName.prefix(while: { $0 != "[" }) == anonymousEventName
    }
    
    
    static func onDevice(_ device: MetaWear) -> [SensorConfig] {
        return SensorConfig.sensors.filter { $0.exists(device.board) }
//        #if TRACKER
//            if let _ = device.accelerometer as? MBLAccelerometerBMI160 {
//                sensors.append(Shock.config)
//                sensors.append(Tilt.config)
//            }
//            if device.temperature != nil {
//                sensors.append(DeltaTemperature.config)
//            }
//            if let _ = device.barometer as? MBLBarometerBosch {
//                sensors.append(DeltaPressure.config)
//            }
//            if device.hygrometer != nil {
//                sensors.append(DeltaHumidity.config)
//            }
//            if device.ambientLight != nil {
//                sensors.append(DeltaAmbientLight.config)
//            }
//        #else
//        #endif
    }
    
    static let accelerometerBMI270 = SensorConfig.Accelerometer(
        values: ["12.5 Hz", "25 Hz", "50 Hz", "100 Hz", "200 Hz", "400 Hz", "800 Hz"],
        frequencyLookup: [12.5, 25.0, 50.0, 100.0, 200.0, 400.0, 800.0],
        valueLookup: [12.5, 25, 50, 100, 200, 400, 800],
        moduleId: MBL_MW_MODULE_ACC_TYPE_BMI270,
        rangeValues: ["±16 Gs", "±8 G's", "±4 G's"," ±2 G's"],
        rangeLookup: [16.0, 8.0, 4.0, 2.0]
    )
    static let accelerometerBMI160 = SensorConfig.Accelerometer(
        values: ["12.5 Hz", "25 Hz", "50 Hz", "100 Hz", "200 Hz", "400 Hz", "800 Hz"],
        frequencyLookup: [12.5, 25.0, 50.0, 100.0, 200.0, 400.0, 800.0],
        valueLookup: [12.5, 25, 50, 100, 200, 400, 800],
        moduleId: MBL_MW_MODULE_ACC_TYPE_BMI160,
        rangeValues: ["±16 Gs", "±8 G's", "±4 G's"," ±2 G's"],
        rangeLookup: [16.0, 8.0, 4.0, 2.0]
    )
    static let accelerometerBMA255 = SensorConfig.Accelerometer(
        values: ["15.62 Hz", "31.26 Hz", "62.5 Hz", "125 Hz", "250 Hz", "500 Hz"],
        frequencyLookup: [15.62, 31.26, 62.5, 125.0, 250.0, 500],
        valueLookup: [15.62, 31.26, 62.5, 125, 250, 500],
        moduleId: MBL_MW_MODULE_ACC_TYPE_BMA255,
        rangeValues: ["±16 Gs", "±8 G's", "±4 G's"," ±2 G's"],
        rangeLookup: [16.0, 8.0, 4.0, 2.0]
    )
    static let accelerometerMMA = SensorConfig.Accelerometer(
        values: ["1.56 Hz", "6.25 Hz", "12.5 Hz", "50 Hz", "100 Hz", "200 Hz", "400 Hz", "800 Hz"],
        frequencyLookup: [1.56, 6.25, 12.5, 50.0, 100.0, 200.0, 400.0, 800.0],
        valueLookup: [1.56, 6.25, 12.5, 50, 100, 200, 400, 800],
        moduleId: MBL_MW_MODULE_ACC_TYPE_MMA8452Q,
        rangeValues: ["±8 G's", "±4 G's"," ±2 G's"],
        rangeLookup: [8.0, 4.0, 2.0]
    )
    static let gyroscopeBMI160 = SensorConfig(
        name: "Gyroscope",
        anonymousEventName: "angular-velocity",
        iconName: "GyroscopeIcon",
        values: ["25 Hz", "50 Hz", "100 Hz", "200 Hz", "400 Hz", "800 Hz"],
        frequencyLookup: [25.0, 50.0, 100.0, 200.0, 400.0, 800.0],
        valueLookup: [MBL_MW_GYRO_BOSCH_ODR_25Hz, MBL_MW_GYRO_BOSCH_ODR_50Hz,
                      MBL_MW_GYRO_BOSCH_ODR_100Hz, MBL_MW_GYRO_BOSCH_ODR_200Hz,
                      MBL_MW_GYRO_BOSCH_ODR_400Hz, MBL_MW_GYRO_BOSCH_ODR_800Hz],
        exclusiveWith: fusedSensors,
        csvHeader: "x-axis (deg/s),y-axis (deg/s),z-axis (deg/s)",
        samplesPerPacket: 2,
        configure: { (board, state) in
            mbl_mw_gyro_bmi160_set_range(board, state.sensor.selectedRange.map { $0 as! MblMwGyroBoschRange } ?? MBL_MW_GYRO_BOSCH_RANGE_2000dps)
            mbl_mw_gyro_bmi160_set_odr(board, state.sensor.selectedValue as! MblMwGyroBoschOdr)
            mbl_mw_gyro_bmi160_write_config(board)
            return Task<()>(())
        },
        start: { (board) in
            mbl_mw_gyro_bmi160_enable_rotation_sampling(board)
            mbl_mw_gyro_bmi160_start(board)
        },
        signal: { (board, state) in
            let signal = mbl_mw_gyro_bmi160_get_rotation_data_signal(board)!
            guard state.isStreaming else {
                return Task<OpaquePointer>(signal)
            }
            return signal.packerCreate(count: 2)
        },
        exists: { (board) in
            return mbl_mw_metawearboard_lookup_module(board, MBL_MW_MODULE_GYRO) == MBL_MW_MODULE_GYRO_TYPE_BMI160
        },
        rangeValues: ["2000 °/s", "1000 °/s", "500 °/s", "250 °/s", "125 °/s"],
        rangeLookup: [MBL_MW_GYRO_BOSCH_RANGE_2000dps, MBL_MW_GYRO_BOSCH_RANGE_1000dps,
                      MBL_MW_GYRO_BOSCH_RANGE_500dps, MBL_MW_GYRO_BOSCH_RANGE_250dps,
                      MBL_MW_GYRO_BOSCH_RANGE_125dps]
    )
    static let gyroscopeBMI270 = SensorConfig(
        name: "Gyroscope",
        anonymousEventName: "angular-velocity",
        iconName: "GyroscopeIcon",
        values: ["25 Hz", "50 Hz", "100 Hz", "200 Hz", "400 Hz", "800 Hz"],
        frequencyLookup: [25.0, 50.0, 100.0, 200.0, 400.0, 800.0],
        valueLookup: [MBL_MW_GYRO_BOSCH_ODR_25Hz, MBL_MW_GYRO_BOSCH_ODR_50Hz,
                      MBL_MW_GYRO_BOSCH_ODR_100Hz, MBL_MW_GYRO_BOSCH_ODR_200Hz,
                      MBL_MW_GYRO_BOSCH_ODR_400Hz, MBL_MW_GYRO_BOSCH_ODR_800Hz],
        exclusiveWith: fusedSensors,
        csvHeader: "x-axis (deg/s),y-axis (deg/s),z-axis (deg/s)",
        samplesPerPacket: 2,
        configure: { (board, state) in
            mbl_mw_gyro_bmi270_set_range(board, state.sensor.selectedRange.map { $0 as! MblMwGyroBoschRange } ?? MBL_MW_GYRO_BOSCH_RANGE_2000dps)
            mbl_mw_gyro_bmi270_set_odr(board, state.sensor.selectedValue as! MblMwGyroBoschOdr)
            mbl_mw_gyro_bmi270_write_config(board)
            return Task<()>(())
        },
        start: { (board) in
            mbl_mw_gyro_bmi270_enable_rotation_sampling(board)
            mbl_mw_gyro_bmi270_start(board)
        },
        signal: { (board, state) in
            let signal = mbl_mw_gyro_bmi270_get_rotation_data_signal(board)!
            guard state.isStreaming else {
                return Task<OpaquePointer>(signal)
            }
            return signal.packerCreate(count: 2)
        },
        exists: { (board) in
            return mbl_mw_metawearboard_lookup_module(board, MBL_MW_MODULE_GYRO) == MBL_MW_MODULE_GYRO_TYPE_BMI270
        },
        rangeValues: ["2000 °/s", "1000 °/s", "500 °/s", "250 °/s", "125 °/s"],
        rangeLookup: [MBL_MW_GYRO_BOSCH_RANGE_2000dps, MBL_MW_GYRO_BOSCH_RANGE_1000dps,
                      MBL_MW_GYRO_BOSCH_RANGE_500dps, MBL_MW_GYRO_BOSCH_RANGE_250dps,
                      MBL_MW_GYRO_BOSCH_RANGE_125dps]
    )
    static let magnetometer = SensorConfig(
        name: "Magnetometer",
        anonymousEventName: "magnetic-field",
        iconName: "MagnetometerIcon",
        values: ["10 Hz", "15 Hz", "20 Hz", "25 Hz"],
        frequencyLookup: [10.0, 15.0, 20.0, 25.0],
        valueLookup: [MBL_MW_MAG_BMM150_ODR_10Hz, MBL_MW_MAG_BMM150_ODR_15Hz,
                      MBL_MW_MAG_BMM150_ODR_20Hz, MBL_MW_MAG_BMM150_ODR_25Hz],
        exclusiveWith: fusedSensors,
        csvHeader: "x-axis (T),y-axis (T),z-axis (T)",
        samplesPerPacket: 2,
        configure: { (board, state) in
            mbl_mw_mag_bmm150_configure(board, 9, 15, state.sensor.selectedValue as! MblMwMagBmm150Odr)
            return Task<()>(())
        },
        start: { (board) in
            mbl_mw_mag_bmm150_enable_b_field_sampling(board)
            mbl_mw_mag_bmm150_start(board)
        },
        signal: { (board, state) in
            let signal = mbl_mw_mag_bmm150_get_b_field_data_signal(board)!
            guard state.isStreaming else {
                return Task<OpaquePointer>(signal)
            }
            return signal.packerCreate(count: 2)
        },
        exists: { (board) in
            return mbl_mw_metawearboard_lookup_module(board, MBL_MW_MODULE_MAGNETOMETER) != MBL_MW_MODULE_TYPE_NA
        },
        writeValue: { (data, state) in
            let tmp: MblMwCartesianFloat = data.valueAs()
            let values = String(format: "%.9f,%.9f,%.9f", tmp.x / 1000000.0, tmp.y / 1000000.0, tmp.z / 1000000.0)
            let row = "\n" + state.header(data) + values
            state.csv.write(row)
        }
    )
    static let temperature = TemperatureSetting()
    static let pressureBMP280 = SensorConfig.Pressure(
        values: ["0.25 Hz", "0.50 Hz", "0.99 Hz", "1.96 Hz", "3.82 Hz", "7.33 Hz", "13.5 Hz", "83.3 Hz"],
        frequencyLookup: [0.25, 0.50, 0.99, 1.96, 3.82, 7.33, 13.5, 83.3],
        valueLookup: [MBL_MW_BARO_BMP280_STANDBY_TIME_4000ms,
                      MBL_MW_BARO_BMP280_STANDBY_TIME_2000ms,
                      MBL_MW_BARO_BMP280_STANDBY_TIME_1000ms,
                      MBL_MW_BARO_BMP280_STANDBY_TIME_500ms,
                      MBL_MW_BARO_BMP280_STANDBY_TIME_250ms,
                      MBL_MW_BARO_BMP280_STANDBY_TIME_125ms,
                      MBL_MW_BARO_BMP280_STANDBY_TIME_62_5ms,
                      MBL_MW_BARO_BMP280_STANDBY_TIME_0_5ms],
        configure: { (board, state) in
            mbl_mw_baro_bosch_set_iir_filter(board, MBL_MW_BARO_BOSCH_IIR_FILTER_OFF)
            mbl_mw_baro_bosch_set_oversampling(board, MBL_MW_BARO_BOSCH_OVERSAMPLING_STANDARD)
            mbl_mw_baro_bmp280_set_standby_time(board, state.sensor.selectedValue as! MblMwBaroBmp280StandbyTime)
            mbl_mw_baro_bosch_write_config(board)
            return Task<()>(())
        },
        moduleId: MBL_MW_MODULE_BARO_TYPE_BMP280
    )
    static let pressureBME280 = SensorConfig.Pressure(
        values: ["0.99 Hz", "1.96 Hz", "3.82 Hz", "7.33 Hz", "13.5 Hz", "31.8 Hz", "46.5 Hz", "83.3 Hz"],
        frequencyLookup: [0.99, 1.96, 3.82, 7.33, 13.5, 31.8, 46.5, 83.3],
        valueLookup: [MBL_MW_BARO_BME280_STANDBY_TIME_1000ms,
                      MBL_MW_BARO_BME280_STANDBY_TIME_500ms,
                      MBL_MW_BARO_BME280_STANDBY_TIME_250ms,
                      MBL_MW_BARO_BME280_STANDBY_TIME_125ms,
                      MBL_MW_BARO_BME280_STANDBY_TIME_62_5ms,
                      MBL_MW_BARO_BME280_STANDBY_TIME_20ms,
                      MBL_MW_BARO_BME280_STANDBY_TIME_10ms,
                      MBL_MW_BARO_BME280_STANDBY_TIME_0_5ms],
        configure: { (board, state) in
            mbl_mw_baro_bosch_set_iir_filter(board, MBL_MW_BARO_BOSCH_IIR_FILTER_OFF)
            mbl_mw_baro_bosch_set_oversampling(board, MBL_MW_BARO_BOSCH_OVERSAMPLING_STANDARD)
            mbl_mw_baro_bme280_set_standby_time(board, state.sensor.selectedValue as! MblMwBaroBme280StandbyTime)
            mbl_mw_baro_bosch_write_config(board)
            return Task<()>(())
        },
        moduleId: MBL_MW_MODULE_BARO_TYPE_BME280
    )
    static let humidity = TimedSensorConfig(
        name: "Humidity",
        anonymousEventName: "relative-humidity",
        iconName: "HumidityIcon",
        values: ["1 hr", "30 m", "15 m", "1 m", "30 s", "15 s", "1 s"],
        frequencyLookup: [1.0 / (1*60*60), 1.0 / (30*60), 1.0 / (15*60), 1.0 / (1*60), 1.0 / (30),  1.0 / (15), 1.0 / (1)],
        valueLookup: [1*60*60*1000, 30*60*1000, 15*60*1000, 1*60*1000, 30*1000, 15*1000, 1*1000] as [UInt32],
        exclusiveWith: [],
        csvHeader: "relative humidity (%)",
        signal: { (board, state) in
            return Task<OpaquePointer>(mbl_mw_humidity_bme280_get_percentage_data_signal(board))
        },
        exists: { (board) in
            return mbl_mw_metawearboard_lookup_module(board, MBL_MW_MODULE_HUMIDITY) != MBL_MW_MODULE_TYPE_NA
        }
    )
    static let ambientLight = SensorConfig(
        name: "Ambient Light",
        anonymousEventName: "illuminance",
        iconName: "AmbientLightIcon",
        values: ["0.5 Hz", "1 Hz", "2 Hz", "5 Hz", "10 Hz"],
        frequencyLookup: [0.5, 1.0, 2.0, 5.0, 10.0],
        valueLookup: [MBL_MW_ALS_LTR329_RATE_2000ms, MBL_MW_ALS_LTR329_RATE_1000ms,
                      MBL_MW_ALS_LTR329_RATE_500ms, MBL_MW_ALS_LTR329_RATE_200ms,
                      MBL_MW_ALS_LTR329_RATE_100ms],
        exclusiveWith: [],
        csvHeader: "illuminance (lx)",
        configure: { (board, state) in
            mbl_mw_als_ltr329_set_gain(board, MBL_MW_ALS_LTR329_GAIN_1X)
            mbl_mw_als_ltr329_set_integration_time(board, MBL_MW_ALS_LTR329_TIME_100ms)
            mbl_mw_als_ltr329_set_measurement_rate(board, state.sensor.selectedValue as! MblMwAlsLtr329MeasurementRate)
            mbl_mw_als_ltr329_write_config(board)
            return Task<()>(())
        },
        start: { (board) in
            mbl_mw_als_ltr329_start(board)
        },
        signal: { (board, state) in
            return Task<OpaquePointer>(mbl_mw_als_ltr329_get_illuminance_data_signal(board))
        },
        exists: { (board) in
            return mbl_mw_metawearboard_lookup_module(board, MBL_MW_MODULE_AMBIENT_LIGHT) != MBL_MW_MODULE_TYPE_NA
        },
        writeValue: { (data, state) in
            let tmp: UInt32 = data.valueAs()
            let values = String(format: "%.3f", Double(tmp) / 1000.0)
            let row = "\n" + state.header(data) + values
            state.csv.write(row)
        }
    )
    static let color = TimedSensorConfig(
        name: "Color",
        anonymousEventName: "color",
        iconName: "ColorIcon",
        values: ["1 Hz", "25 Hz", "50 Hz", "100 Hz"],
        frequencyLookup: [1.0, 25.0, 50.0, 100.0],
        valueLookup: [1000 / 1, 1000 / 25, 1000 / 50, 1000 / 100] as [UInt32],
        exclusiveWith: [],
        csvHeader: "red (counts),green (counts),blue (counts),clear (counts)",
        signal: { (board, state) in
            return Task<OpaquePointer>(mbl_mw_cd_tcs34725_get_adc_data_signal(board))
        },
        exists: { (board) in
            return mbl_mw_metawearboard_lookup_module(board, MBL_MW_MODULE_COLOR_DETECTOR) != MBL_MW_MODULE_TYPE_NA
        },
        extraConfigure: { (board, state) in
            mbl_mw_cd_tcs34725_set_gain(board, MBL_MW_CD_TCS34725_GAIN_1X)
            mbl_mw_cd_tcs34725_disable_illuminator_led(board)
            let times = [700.0, 36.0, 16.8, 7.2] as [Float]
            mbl_mw_cd_tcs34725_set_integration_time(board, times[state.sensor.selectedIdx!])
            mbl_mw_cd_tcs34725_write_config(board)
            return Task<()>(())
        }
    )
    static let proximity = TimedSensorConfig(
        name: "Proximity",
        anonymousEventName: "proximity",
        iconName: "ProximityIcon",
        values: ["1 Hz", "25 Hz", "50 Hz", "100 Hz"],
        frequencyLookup: [1.0, 25.0, 50.0, 100.0],
        valueLookup: [1000 / 1, 1000 / 25, 1000 / 50, 1000 / 100] as [UInt32],
        exclusiveWith: [],
        csvHeader: "proximity (counts)",
        signal: { (board, state) in
            return Task<OpaquePointer>(mbl_mw_proximity_tsl2671_get_adc_data_signal(board))
        },
        exists: { (board) in
            return mbl_mw_metawearboard_lookup_module(board, MBL_MW_MODULE_PROXIMITY) != MBL_MW_MODULE_TYPE_NA
        },
        extraConfigure: { (board, state) in
            mbl_mw_proximity_tsl2671_set_transmitter_current(board, MBL_MW_PROXIMITY_TSL2671_CURRENT_12_5mA)
            mbl_mw_proximity_tsl2671_set_integration_time(board, 2.73)
            mbl_mw_proximity_tsl2671_set_n_pulses(board, 1)
            return Task<()>(())
        }
    )
    static let eulerAngle = SensorFusion(
        name: "Euler Angles",
        anonymousEventName: "euler-angles",
        iconName: "EulerAngleIcon",
        csvHeader: "pitch (deg),roll (deg),yaw (deg),heading (deg)",
        type: MBL_MW_SENSOR_FUSION_DATA_EULER_ANGLE,
        mask: 0xff
    )
    static let gravity = SensorFusion(
        name: "Gravity",
        anonymousEventName: "gravity",
        iconName: "GravityIcon",
        csvHeader: "x-axis (g),y-axis (g),z-axis (g)",
        type: MBL_MW_SENSOR_FUSION_DATA_GRAVITY_VECTOR,
        mask: 0xffffffff
    )
    static let linearAcceleration = SensorFusion(
        name: "Linear Acceleration",
        anonymousEventName: "linear-acceleration",
        iconName: "LinearAccelerationIcon",
        csvHeader: "x-axis (g),y-axis (g),z-axis (g)",
        type: MBL_MW_SENSOR_FUSION_DATA_LINEAR_ACC,
        mask: 0xffffffff
    )
    static let quaternion = SensorFusion(
        name: "Quaternion",
        anonymousEventName: "quaternion",
        iconName: "QuaternionIcon",
        csvHeader: "w (number),x (number),y (number),z (number)",
        type: MBL_MW_SENSOR_FUSION_DATA_QUATERNION,
        mask: 0xff
    )
    
    static let sensors: [SensorConfig] = [
        accelerometerBMI270,
        accelerometerBMI160,
        accelerometerBMA255,
        accelerometerMMA,
        gyroscopeBMI160,
        gyroscopeBMI270,
        magnetometer,
        temperature,
        pressureBMP280,
        pressureBME280,
        humidity,
        ambientLight,
        color,
        proximity,
        eulerAngle,
        gravity,
        linearAcceleration,
        quaternion
    ]
}

class TimedSensorConfig: SensorConfig {
    var timers: [OpaquePointer: OpaquePointer] = [:]
    
    init(name: String, anonymousEventName: String, iconName: String, values: [String],
         frequencyLookup: [Double], valueLookup: [UInt32], exclusiveWith: [String],
         csvHeader: String, signal: SignalFn! = nil,
         exists: ExistsFn! = nil, extraConfigure: ConfigureFn? = nil,
         writeValue: WriteFn! = {$1.csv.write($1.csvRow($0))}) {
        super.init(name: name,
                   anonymousEventName: anonymousEventName,
                   iconName: iconName,
                   values: values,
                   frequencyLookup: frequencyLookup,
                   valueLookup: valueLookup,
                   exclusiveWith: exclusiveWith,
                   csvHeader: csvHeader,
                   configure: nil,
                   start: nil,
                   signal: signal,
                   exists: exists,
                   writeValue: writeValue)
        
        configure = { (board, state) in
            let task = extraConfigure?(board, state) ?? Task<Void>(())
            return task.continueOnSuccessWithTask { _ in
                return board.timerCreate(period: state.sensor.selectedValue as! UInt32)
            }.continueOnSuccessWithTask { timer in
                return self.signal(board, state).continueOnSuccessWithTask { signal -> Task<Void> in
                    mbl_mw_event_record_commands(timer)
                    mbl_mw_datasignal_read(signal)
                    return timer.eventEndRecord().continueOnSuccessWith {
                        self.timers[board] = timer
                    }
                }
            }
        }
        start = { (board) in
            mbl_mw_timer_start(self.timers[board])
        }
    }
}

class TemperatureSetting: TimedSensorConfig {
    var thermistorChannels: [OpaquePointer: UInt8] = [:]
    
    init() {
        super.init(name: "Temperature",
                   anonymousEventName: "temperature",
                   iconName: "TemperatureIcon",
                   values: ["1 hr", "30 m", "15 m", "1 m", "30 s", "15 s", "1 s"],
                   frequencyLookup: [1.0 / (1*60*60), 1.0 / (30*60), 1.0 / (15*60), 1.0 / (1*60), 1.0 / (30),  1.0 / (15), 1.0 / (1)],
                   valueLookup: [1*60*60*1000, 30*60*1000, 15*60*1000, 1*60*1000, 30*1000, 15*1000, 1*1000] as [UInt32],
                   exclusiveWith: [],
                   csvHeader: "temperature (C)",
                   signal: nil,
                   exists: nil)
        
        signal = { (board, streaming) in
            return Task<OpaquePointer>(mbl_mw_multi_chnl_temp_get_temperature_data_signal(board, self.thermistorChannels[board]!))
        }
        exists = { (board) in
            for channel in 0..<mbl_mw_multi_chnl_temp_get_num_channels(board) {
                if mbl_mw_multi_chnl_temp_get_source(board, channel) == MBL_MW_TEMPERATURE_SOURCE_PRESET_THERM {
                    self.thermistorChannels[board] = channel;
                    return true
                }
            }
            return false
        }
    }
}
