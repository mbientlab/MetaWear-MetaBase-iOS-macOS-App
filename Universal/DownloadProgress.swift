//
//  DownloadProgress.swift
//  MetaBase
//
//  Created by Stephen Schiffli on 1/12/18.
//  Copyright © 2018 MBIENTLAB, INC. All rights reserved.
//

import MetaWear
import MetaWearCpp

protocol DownloadProgressDelegate: class {
    func didUpdateCaptureProgress(_ download: DownloadProgress, progress: Double)
    func didFinish(_ download: DownloadProgress)
}

class DownloadProgress {
    weak var delegate: DownloadProgressDelegate?
    let start = Date()
    var handlers = MblMwLogDownloadHandler()
    let device: MetaWear
    var prevProgress = 0.0
    var finished = false

    init(delegate: DownloadProgressDelegate, device: MetaWear) {
        self.delegate = delegate
        self.device = device

        handlers.context = bridgeRetained(obj: self)
        handlers.received_progress_update = { (contextPtr, remainingEntries, totalEntries) in
            let _self: DownloadProgress = bridge(ptr: contextPtr!)
            var progress = Double(totalEntries - remainingEntries) / Double(totalEntries)
            // Make sure progress is always [0.0,1.0]
            progress = min(progress, 1.0)
            progress = max(progress, 0.0)
            if abs(_self.prevProgress - progress) > 0.01 {
                _self.prevProgress = progress
                _self.delegate?.didUpdateCaptureProgress(_self, progress: progress)
            }
            if remainingEntries == 0 {
                _self.finished = true
                _self.delegate?.didFinish(_self)
            }
        }
        handlers.received_unknown_entry = { (context, id, epoch, data, length) in
            print("received_unknown_entry")
        }
        handlers.received_unhandled_entry = { (context, data) in
            print("received_unhandled_entry")
        }
    }
}
