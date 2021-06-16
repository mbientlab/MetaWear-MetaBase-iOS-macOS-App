//
//  State.swift
//  MetaBase
//
//  Created by Stephen Schiffli on 1/12/18.
//  Copyright © 2018 MBIENTLAB, INC. All rights reserved.
//

import MetaWear
import MetaWearCpp
import BoltsSwift

fileprivate let dateFormatter = DateFormatter { $0.dateFormat = "yyyy-MM-dd'T'HH.mm.ss.SSS" }

class State {
    let sensor: SensorConfig
    let device: MetaWear
    let isStreaming: Bool
    let period: TimeInterval
    let mask: Int64
    let handler: MblMwFnData
    var csvFilename: String = ""
    let tmpCsvUrl: URL
    let csv: OutputStream
    var first: TimeInterval?
    var next: TimeInterval?
    var prev: UInt32?
    var sampleCount = 0
    
    init(sensor: SensorConfig, device: MetaWear, isStreaming: Bool) {
        self.sensor = sensor
        self.device = device
        self.isStreaming = isStreaming
        self.period = sensor.period
        self.mask = sensor.mask
        self.handler = { (contextPtr, pointer) in
            let context = bridge(ptr: contextPtr!) as State
            context.sampleCount += 1
            context.sensor.writeValue(pointer!.pointee, context)
        }
        // Point our csv writer to the temporary data dump
        var url = Constants.pendingDirectory
        url.appendPathComponent(device.pathSafeMac, isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        url.appendPathComponent(sensor.pathSafeName)
        url.appendPathExtension("csv")
        self.tmpCsvUrl = url
        
        let results = url.processExistingFile()
        self.first = results.epoc
        self.sampleCount = results.count
        if !results.exists {
            FileManager.default.createFile(atPath: url.absoluteString, contents: nil, attributes: nil)
        }
        self.csv = OutputStream(url: url, append: results.exists)!
        self.csv.open()
        if !results.exists {
            csv.write(sensor.csvHeader)
        }
    }
    
    // Used to finish a capture.  Moves data out of the pending directory
    func finishCsvFile(_ startingTime: Date) {
        // Build a friendly filename -- GivenName or AdName_LocalTime_MAC_Sensor.csv
        let dateString = Constants.dateFormatter.string(from: startingTime)
        let sensorName = sensor.pathSafeName
        let mac = device.pathSafeMac
        csvFilename = "\(device.metadata.name)_\(dateString)_\(mac)_\(sensorName).csv"
        let finalUrl = csvFilename.documentDirectoryUrl
        // Move from pending data
        try? FileManager.default.removeItem(at: finalUrl)
        try? FileManager.default.moveItem(at: tmpCsvUrl, to: finalUrl)
    }
    
    func calcRealEpoch(_ data: MblMwData) -> TimeInterval {
        guard isStreaming else {
            let epoch = Double(data.epoch) / 1000
            if first == nil {
                first = epoch
            }
            return epoch
        }
        let epoch = Date().timeIntervalSince1970
        if first == nil {
            first = epoch
        }
        let count: UInt32 = data.extraAs()
        if prev == nil {
            prev = count
            next = epoch
        } else if prev! == count {
            next! += period
        }
        
        if count < prev! {
            let diff = (Int64(count) - Int64(prev!)) & mask
            next! += (Double(diff) * period)
        } else {
            next! += (Double(count - prev!) * period)
        }
        prev = count
        return next!
    }
    
    func header(_ data: MblMwData) -> String {
        let epoch = calcRealEpoch(data)
        let timestamp = Date(timeIntervalSince1970: epoch)
        let elapsed = epoch - first!
        let head = "\(String(UInt64(round(epoch * 1000.0)))),\(dateFormatter.string(from: timestamp)),\(String(format: "%.3f", elapsed)),"
        return head
    }
    
    func csvRow(_ data: MblMwData) -> String {
        return "\n" + header(data) + data.values()
    }
}

extension Sequence where Iterator.Element == State {
    var oldestTimestamp: Date {
        get {
            let leastEpoc = self.min {
                guard let a = $0.first, let b = $1.first else {
                    return false
                }
                return a < b
            }
            return Date(timeIntervalSince1970: Double(leastEpoc?.first ?? 0))
        }
    }
    var newestTimestamp: Date {
        get {
            let leastEpoc = self.max {
                guard let a = $0.first, let b = $1.first else {
                    return false
                }
                return a < b
            }
            return Date(timeIntervalSince1970: Double(leastEpoc?.first ?? 0))
        }
    }
}

extension MetaWear {
    var pathSafeMac: String {
        get {
            return (mac ?? "FF:FF:FF:FF:FF:FF").uppercased().replacingOccurrences(of: ":", with: "", options: NSString.CompareOptions.literal, range: nil)
        }
    }
}

extension SensorConfig {
    var pathSafeName: String {
        get {
            return name.replacingOccurrences(of: " ", with: "", options: NSString.CompareOptions.literal, range: nil)
        }
    }
}

extension URL {
    func processExistingFile() -> (epoc: Double?, count: Int, exists: Bool) {
        guard let file = try? String(contentsOf: self, encoding: .utf8) else {
            return (nil, 0, false)
        }
        let lines = file.components(separatedBy: .newlines)
        guard lines.count > 0 else {
            return (nil, 0, false)
        }
        let count = lines.count - 1
        let epoc = lines.count > 1 ? Int64(lines[1].components(separatedBy: ",")[0]) : nil
        return (epoc != nil ? Double(epoc!) / 1000.0 : nil, count, true)
    }
}
