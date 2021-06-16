//
//  StreamTableViewController.swift
//  MetaBase
//
//  Created by Stephen Schiffli on 5/18/17.
//  Copyright © 2017 MBIENTLAB, INC. All rights reserved.
//

import UIKit
import MetaWear
import BoltsSwift
import CoreBluetooth
//import FirebaseAnalytics

extension MetaWear {
    @discardableResult
    func autoReconnectAndSetup(retries: Int = 3, needsReset: Bool = true, source: TaskCompletionSource<()> = TaskCompletionSource<()>()) -> Task<()> {
        // Inform the caller we failed
        guard retries > 0 else {
            source.trySet(error: MetaWearError.operationFailed(message: "cannot connect"))
            return source.task
        }
        // Begin the connect loop
        connectAndSetup().continueWith(.queue(DispatchQueue.global())) { [weak self] t in
            // Don't reconnect a cancelled connection
            guard !t.cancelled else {
                return
            }
            // But do reconnect on any other errors
            guard let disconnectTask = t.result else {
                self?.autoReconnectAndSetup(retries: retries - 1, source: source)
                return
            }
            if needsReset {
                self?.clearAndReset()
            } else {
                // Inform the caller we succeeded
                source.trySet(result: ())
            }
            // Watch for unexpected disconnects and automatically request another connection
            disconnectTask.continueWith(.queue(DispatchQueue.global())) { [weak self] t in
                guard !needsReset else {
                    self?.autoReconnectAndSetup(retries: 10, needsReset: false, source: source)
                    return
                }
                // If no fault then this is an expected disconnect
                guard t.faulted else {
                    return
                }
                // On reconnect be generous and give it 10 retries
                self?.autoReconnectAndSetup(retries: 10, needsReset: false)
            }
        }
        return source.task
    }
}

class StreamTableViewController: UIViewController {
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var tableView: UITableView!

    var devices: [MetaWear] = []
    var deviceState: [MetaWear: [State]] = [:]
    var timer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    @objc func appDidBecomeActive() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: Constants.streamUpdateInterval, repeats: true) { [weak self] _ in
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? CaptureViewController {
            destination.startStreamCaptures(deviceState)
        }
    }
    
    func startStream(_ devices: [MetaWear]) {
        self.devices = devices
        for device in devices {
            deviceState[device] = []
            device.autoReconnectAndSetup().continueWith { t in
                guard !t.faulted else {
                    self.showOKAlert("Error", message: t.error!.localizedDescription)
                    return
                }
                CommandStream.start(device, configs: SensorConfig.sensors).continueWith { t in
                    guard !t.faulted else {
                        self.showOKAlert("Error", message: t.error!.localizedDescription)
                        return
                    }
                    self.deviceState[device] = t.result!
                }
            }
        }
    }
    
    @IBAction func stopStream(_ sender: Any) {
        performSegue(withIdentifier: "ShowCapture", sender: nil)
    }
}

extension StreamTableViewController: UITableViewDelegate {
}

extension StreamTableViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return devices.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "StreamCell", for: indexPath) as! StreamTableViewCell
        let device = devices[indexPath.row]
        if let state = deviceState[device] {
            cell.updateUI(device, state: state)
        }
        return cell
    }
}

extension StreamTableViewController {
    func streamSetupFinishedWithError(_ error: Error?) {
        DispatchQueue.main.async {
            var title = "SUCCESS"
            var message = "The sensors have been configured and started streaming data."
            var OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            
            if let error = error {
                title = "ERROR"
                message = error.localizedDescription + "  Please try again."
                OKAction = UIAlertAction(title: "OK", style: .default) { (action) in
                    self.dismiss(animated: true)
                }
            }
            
            let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
            alertController.addAction(OKAction)
            self.present(alertController, animated: true)
        }
    }
}
