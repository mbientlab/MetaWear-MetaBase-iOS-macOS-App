// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import MetaWear
import MetaWearCpp
#if os(iOS)
import UIKit
#endif

class DiagnosticData {
    #if os(macOS)
    let hostDevice = "Cores \(ProcessInfo.processInfo.processorCount) Memory \(ProcessInfo.processInfo.physicalMemory)"
    let os = "macOS"
    #elseif os(iOS)
    let hostDevice = "\(UIDevice.current.model)"
    let os = "\(UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone")"
    #endif
    let osVersion = "\(ProcessInfo.processInfo.operatingSystemVersionString)"

    let app: String
    let appRevision: String
    let mac: String
    let model: String
    let modelNumber: String
    let firmware: String
    let hardware: String
    let serialNumber: String
    let manufacturer: String
    let rssi: String
    let battery: String

    let json: String

    init(_ device: MetaWear, batteryLevel: String) {
        app = "MetaBase"
        appRevision = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "X.X.X"
        mac = device.info.mac
        model = device.info.model.name // ModelDescription ??
        modelNumber = String(device.info.model.rawValue)
        firmware = device.info.firmwareRevision
        hardware = device.info.hardwareRevision
        serialNumber = device.info.serialNumber
        manufacturer = device.info.manufacturer
        rssi = "\(device.rssi) dBm"
        battery = batteryLevel
        let board = device.board
        var size: UInt32 = 0
        let moduleInfoPtr = mbl_mw_metawearboard_get_module_info(board, &size)
        let moduleInfo = Array(UnsafeBufferPointer(start: moduleInfoPtr, count: Int(size)))
        json = """
{
  "App": "MetaBase",
  "App Revision": "\(appRevision)",
  "Host Device": "\(hostDevice)",
  "OS": "\(os)",
  "OS Version": "\(osVersion)",
  "MAC": "\(mac)",
  "Model": "\(model)",
  "Model Number": "\(modelNumber)",
  "Firmware": "\(firmware)",
  "Hardware": "\(hardware)",
  "Serial Number": "\(serialNumber)",
  "Manufacturer": "\(manufacturer)",
  "RSSI": "\(rssi)",
  "Battery": "\(battery)",
  "Modules": {
    \(moduleInfo.jsonOf("Accelerometer")),
    \(moduleInfo.jsonOf("AmbientLight")),
    \(moduleInfo.jsonOf("Barometer")),
    \(moduleInfo.jsonOf("Color")),
    \(moduleInfo.jsonOf("Conductance")),
    \(moduleInfo.jsonOf("DataProcessor")),
    \(moduleInfo.jsonOf("Debug")),
    \(moduleInfo.jsonOf("Event")),
    \(moduleInfo.jsonOf("Gpio")),
    \(moduleInfo.jsonOf("Gyro")),
    \(moduleInfo.jsonOf("Haptic")),
    \(moduleInfo.jsonOf("Humidity")),
    \(moduleInfo.jsonOf("IBeacon")),
    \(moduleInfo.jsonOf("Led")),
    \(moduleInfo.jsonOf("Logging")),
    \(moduleInfo.jsonOf("Macro")),
    \(moduleInfo.jsonOf("Magnetometer")),
    \(moduleInfo.jsonOf("NeoPixel")),
    \(moduleInfo.jsonOf("Proximity")),
    \(moduleInfo.jsonOf("SensorFusion")),
    \(moduleInfo.jsonOf("SerialPassthrough")),
    \(moduleInfo.jsonOf("Settings")),
    \(moduleInfo.jsonOf("Switch")),
    \(moduleInfo.jsonOf("Temperature")),
    \(moduleInfo.jsonOf("Timer"))
  }
}
"""
        mbl_mw_memory_free(moduleInfoPtr)
    }
}

extension MblMwModuleInfo {
    var json: String {
        guard present != 0 else {
            return ""
        }
        var json = "\n      \"implementation\": \(implementation),\n      \"revision\": \(revision)"
        if extra_len > 0 {
            let buffer = UnsafeBufferPointer(start: extra, count: Int(extra_len))
            json += ",\n      \"extra\": \(Array(buffer).json)"
        }
        json += "\n    "
        return json
    }
}

extension Array where Iterator.Element == MblMwModuleInfo {
    func jsonOf(_ name: String) -> String {
        let value = first { String(cString: $0.name) == name }?.json ?? "N/A"
        return "\"\(name)\": {\(value)}"
    }
}

extension Array where Iterator.Element == UInt8 {
    var json: String {
        guard count > 0 else {
            return ""
        }
        var dataString = reduce("\"[") { (result, cur) in
            return result + "0x" + String(format:"%02x", cur) + ", "
        }
        dataString.removeLast()
        dataString.removeLast()
        dataString += "]\""
        return dataString
    }
}
