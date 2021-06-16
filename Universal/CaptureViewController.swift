//
//  CaptureViewController.swift
//  MetaBase
//
//  Created by Stephen Schiffli on 2/5/16.
//  Copyright © 2016 MBIENTLAB, INC. All rights reserved.
//

import UIKit
import PNChart
import MetaWear
import MetaWearCpp
import BoltsSwift
import MessageUI
//import FirebaseAnalytics
//import Parse

class CaptureViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    var downloadProgress: [DownloadProgress] = []
    var deviceState: [MetaWear: [State]] = [:]
    var downloadSources: [MetaWear: TaskCompletionSource<()>] = [:]
    var timer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    @objc func appDidBecomeActive() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tableView.reloadData()
        }
    }
    
    @objc func appWillResignActive() {
        timer?.invalidate()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        appDidBecomeActive()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        appWillResignActive()
    }
    
    func dismissController(successful: Bool) {
        self.performSegue(withIdentifier: "GoToDetail", sender: successful)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let successful = sender as? Bool else {
            return
        }
        if let destination = segue.destination as? DeviceDetailViewController {
            destination.isRecording = !successful
        }
    }
    
    func startStreamCaptures(_ deviceState: [MetaWear: [State]]) {
        self.deviceState = deviceState
        let tasks = deviceState.map { CommandStream.stop($0.key, state: $0.value) }
        Task.whenAll(tasks).continueWith { t in
            let errors = (t.error as? AggregateError)?.errors ?? []
            self.didCompleteCaptures(errors)
        }
    }
    
    func startLogCaptures(_  devices: [MetaWear]) {
        for device in devices {
            let progress = DownloadProgress(delegate: self, device: device)
            downloadProgress.append(progress)
            downloadSources[device] = TaskCompletionSource<()>()
            device.connectAndSetup().continueOnSuccessWithTask(device.apiAccessExecutor) { _ -> Task<[State]> in
                // The LED flashes blue to indicate download has begun
                device.flashLED(color: .blue, intensity: 1.0, _repeat: 3)
                // Stop the logging of new data
                mbl_mw_logging_stop(device.board)
                // Flush NAND for MMS
                mbl_mw_logging_flush_page(device.board)
                // Setup handlers of the incoming log data
                return CommandDownload.attachSignalHandlers(device, configs: SensorConfig.sensors)
            }.continueWith { t in
                guard !t.faulted else {
                    self.downloadSources[device]?.trySet(error: t.error ?? MetaWearError.operationFailed(message: "download failed"))
                    return
                }
                self.deviceState[device] = t.result ?? []
                // Actually start the log download, this will cause all the handlers we setup to be invoked
                device.autoReconnectAndDownload(progress.handlers)
            }
        }
        Task.whenAll(downloadSources.map { $1.task }).continueWith { t in
            let errors = (t.error as? AggregateError)?.errors ?? []
            self.didCompleteCaptures(errors)
        }
    }
    
    func askIfShipmentDone(_ handler: ((Bool) -> Void)? = nil) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: "Shipment Complete?", message: "Is this the end of the Shipment?", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "No", style: .default) { _ in
                handler?(false)
            })
            alertController.addAction(UIAlertAction(title: "Yes", style: .destructive) { _ in
                handler?(true)
            })
            self.present(alertController, animated: true)
        }
    }
    
    @IBAction func cancelPressed(_ sender: Any) {
        deviceState.forEach {
            $0.key.cancelConnection()
        }
        dismissController(successful: false)
    }
    
    @IBAction func trashPressed(_ sender: AnyObject) {
        // Confirm discard
        let alertController = UIAlertController(title: "Discard Data", message: "Are you sure you want to discard the data?  This operation cannot be undone.", preferredStyle: .actionSheet)
        let discard = UIAlertAction(title: "Discard", style: .destructive) { (action) in
            // Clean up and disconnect from each device
            self.deviceState.forEach {
                guard $0.key.isConnectedAndSetup else {
                    return
                }
                $0.key.clearAndReset()
            }
            self.dismissController(successful: true)
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(discard)
        alertController.addAction(cancel)
        present(alertController, animated: true)
    }
}

extension CaptureViewController: UITableViewDelegate {
}

extension CaptureViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return downloadProgress.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CaptureCell", for: indexPath) as! CaptureTableViewCell
        let progress = downloadProgress[indexPath.row]
        cell.updateUI(progress)
        return cell
    }
}

extension CaptureViewController: DownloadProgressDelegate {
    func didUpdateCaptureProgress(_ download: DownloadProgress, progress: Double) {
        if let key = downloadProgress.index(where: { $0 === download }) {
            DispatchQueue.main.async {
                self.tableView.reloadRows(at: [IndexPath(row: key, section: 0)], with: .none)
            }
        }
    }
    
    func didFinish(_ download: DownloadProgress) {
        //Analytics.logEvent("download_log", parameters: [
        //    "duration": Int(deviceState[download.device]?.oldestTimestamp.timeIntervalSince1970 ?? 0 * -1000.0),
        //    "download_duration": Int(download.start.timeIntervalSinceNow * -1000.0)
        //    ])
        if Constants.isTracker {
            // Reset all the delta filters so they drop a new initial value
            if let characteristic = download.device.getCharacteristic(.metaWearService,
                                                             .metaWearCommand).characteristic {
                for i in UInt8(0)..<4 {
                    download.device.peripheral.writeValue(Data(bytes: [0x09, 0x04, i, 0xFF, 0xFF, 0xFF, 0x7F]), for: characteristic, type: .withoutResponse)
                }
            }
        } else {
            download.device.clearAndReset()
        }
        downloadSources[download.device]?.trySet(result: ())
    }
}

extension CaptureViewController {
    func didCompleteCaptures(_ _errors: [Error], wasError: Bool = false) {
        guard _errors.isEmpty else {
            var errors = _errors
            let cur = errors.removeFirst()
            self.showOKAlert("Error", message: cur.localizedDescription) { _ in
                self.didCompleteCaptures(errors, wasError: true)
            }
            return
        }
        
        let states = deviceState.flatMap{$0.value}.filter{$0.first != nil}
        guard !states.isEmpty else {
            DispatchQueue.main.async {
                self.dismissController(successful: !wasError)
            }
            return
        }

//        // TODO
//        guard !Constants.isTracker else {
//            trackerAutoSync()
//            return
//        }
        
        showSessionNameInput { note in
            // Save the csv files to a safe, permanent place
            let oldest = states.oldestTimestamp
            states.forEach { $0.finishCsvFile(oldest) }
            // Create a persistent model of the session
            for (device, states) in self.deviceState {
                device.metadata.sessions.append(SessionModel(device: device, started: oldest, states: states, note: note))
                device.metadata.save()
            }
            DispatchQueue.main.async {
                self.dismissController(successful: true)
            }
        }
    }
    
//    func trackerAutoSync() {
//        guard let user = PFUser.current() else {
//            // TODO self.showLogin()
//            return
//        }
//        askIfShipmentDone { isComplete in
//            if isComplete {
//                for device in self.deviceState.keys {
//                    device.connectAndSetup().continueOnSuccessWith { _ in
//                        device.clearAndReset()
//                    }
//                }
//            }
//            PFGeoPoint.geoPointForCurrentLocation { (location, error) in
//                var objects: [PFObject] = self.deviceState.map { Session.from(model: $0.key.metadata.sessions.last!, user: user, location: location) }
//                if isComplete {
//                    for shipmentId in self.deviceState.map({ $0.key.scanResponsePayload }) {
//                        if let shipmentId = shipmentId {
//                            let shipment = Shipment(withoutDataWithObjectId: shipmentId)
//                            shipment.state = 1
//                            objects.append(shipment)
//                        }
//                    }
//                }
//                PFObject.saveAll(inBackground: objects) { (success, error) in
//                    if let error = error {
//                        self.showOKAlert("Error", message: error.localizedDescription) { _ in
//                            self.dismissController(successful: true)
//                        }
//                    } else {
//                        DispatchQueue.main.async {
//                            self.dismissController(successful: true)
//                        }
//                    }
//                }
//            }
//        }
//    }
}

extension MetaWear {
    func autoReconnectAndDownload(_ _handlers: MblMwLogDownloadHandler) {
        var handlers = _handlers
        // On disconnect we save state to keep the "last delieverd timestamp"
        // value and prevent duplicates on reconnect
        let state = Data(bytes: serialize())
        try? state.write(to: uniqueUrl,
                         options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        
        // Begin the connect loop
        connectAndSetup().continueWith(apiAccessExecutor) { [weak self] t in
            // Don't reconnect a cancelled connection
            guard !t.cancelled else {
                return
            }
            // But do reconnect on any other errors
            guard let disconnectTask = t.result else {
                self?.autoReconnectAndDownload(handlers)
                return
            }
            guard let strongSelf = self, let board = strongSelf.board else {
                return
            }
            // Fire off the download
            mbl_mw_logging_download(board, 100, &handlers)
            // Watch for unexpected disconnects and automatically request another connection
            disconnectTask.continueWith(strongSelf.apiAccessExecutor) { [weak self] t in
                // If no fault then this is an expected disconnect
                guard t.faulted else {
                    return
                }
                // On reconnect be generous and give it 10 retries
                self?.autoReconnectAndDownload(handlers)
            }
        }
    }
}

