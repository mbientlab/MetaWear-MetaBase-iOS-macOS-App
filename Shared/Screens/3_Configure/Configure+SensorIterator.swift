// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import SwiftUI
import mbientSwiftUI
import MetaWear

extension ConfigureScreen {

    struct SensorIterator: View {

        @EnvironmentObject private var vm: SensorConfigurationVM
        @State private var placeholder = MWFrequency.CommonCases.hz50
        @Namespace var namespace

        var body: some View {
            exclusive3Dsensors
            otherSensors
        }

        @ViewBuilder private var exclusive3Dsensors: some View {
            if vm.options.accelerometer {
                Tile(
                    module: "Accelerometer",
                    symbol: .accelerometer,
                    isSelected: .init(get: { vm.config.accelerometer }, set: { _ in vm.toggleAccelerometer() }),
                    frequency: $vm.config.accelerometerRate,
                    frequencies: vm.options.accelerometerRate,
                    option: $vm.config.accelerometerScale,
                    options: vm.options.accelerometerScale,
                    optionsHelp: "Scale"
                )
            }
            if vm.options.gyroscope {
                Tile(
                    module: "Gyroscope",
                    symbol: .gyroscope,
                    isSelected: .init(get: { vm.config.gyroscope },
                                      set: { _ in vm.toggleGyroscope() }),
                    frequency: $vm.config.gyroscopeRate,
                    frequencies: vm.options.gyroscopeRate,
                    option: $vm.config.gyroscopeScale,
                    options: vm.options.gyroscopeScale,
                    optionsHelp: "Scale"
                )

            }
            if vm.options.magnetometer {
                Tile(
                    module: "Magnetometer",
                    symbol: .magnetometer,
                    isSelected: .init(get: { vm.config.magnetometer },
                                      set: { _ in vm.toggleMagnetometer() }),
                    frequency: $vm.config.magnetometerRate,
                    frequencies: vm.options.magnetometerRate,
                    option: $placeholder
                )
            }
            if vm.options.fusion {
                Tile(
                    module: "Sensor Fusion",
                    symbol: .sensorFusion,
                    isSelected: .init(get: { vm.config.sensorFusion },
                                      set: { _ in vm.toggleFusion() }),
                    frequency: $vm.config.fusionRate,
                    frequencies: vm.options.fusionRate,
                    option: $vm.config.sensorFusionType,
                    options: vm.options.sensorFusion,
                    optionsHelp: "Output Type",
                    alwaysShowOptions: true
                )
            }
        }

        @ViewBuilder private var otherSensors: some View {
            if vm.options.barometer {
                Tile(
                    module: "Altitude",
                    symbol: .barometer,
                    isSelected: .init(get: { vm.config.altitude },
                                      set: { _ in vm.toggleAltitude() }),
                    frequency: $vm.config.barometerRate,
                    frequencies: vm.options.barometerRate,
                    option: $placeholder
                )
            }
            if vm.options.ambientLight {
                Tile(
                    module: "Ambient Light",
                    symbol: .ambientLight,
                    isSelected: $vm.config.ambientLight,
                    frequency: $vm.config.ambientLightRate,
                    frequencies: vm.options.ambientLightRate,
                    option: $placeholder
                )
            }
            if vm.options.humidity {
                Tile(
                    module: "Humidity",
                    symbol: .hygrometer,
                    isSelected: $vm.config.humidity,
                    frequency: $vm.config.humidityRate,
                    frequencies: vm.options.humidityRate,
                    option: $placeholder
                )
            }
            if vm.options.barometer {
                Tile(
                    module: "Pressure",
                    symbol: .barometer,
                    isSelected: .init(get: { vm.config.pressure },
                                      set: { _ in vm.togglePressure() }),
                    frequency: $vm.config.barometerRate,
                    frequencies: vm.options.barometerRate,
                    option: $placeholder
                )
            }
            if vm.options.temperature {
                Tile(
                    module: "Temperature",
                    symbol: .temperature,
                    isSelected: $vm.config.temperature,
                    frequency: $vm.config.temperatureRate,
                    frequencies: vm.options.temperatureRate,
                    option: $placeholder
                )
            }
        }
    }
}

extension MWAccelerometer.SampleFrequency: Listable {}
extension MWAmbientLight.MeasurementRate: Listable {}
extension MWBarometer.StandbyTime: Listable {}
extension MWGyroscope.Frequency: Listable {}
extension MWMagnetometer.SampleFrequency: Listable {}
extension MWAccelerometer.GravityRange: Listable {}
extension MWGyroscope.GraphRange: Listable {}
extension MWFrequency.CommonCases: Listable {}
extension MWSensorFusion.OutputType: Listable {}
