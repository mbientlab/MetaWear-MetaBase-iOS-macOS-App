//
//  ConfigTableViewController.swift
//  MetaBase
//
//  Created by Stephen Schiffli on 2/5/16.
//  Copyright © 2016 MBIENTLAB, INC. All rights reserved.
//

import UIKit
import MBProgressHUD
import MetaWear
import MetaWearCpp
import BoltsSwift
//import Parse
//import FirebaseAnalytics

fileprivate let MAX_PACKETS_SEC = 100.0

class ConfigTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, ConfigTableViewCellDelegate {
    @IBOutlet weak var xImage: UIImageView!
    @IBOutlet weak var checkImage: UIImageView!
    @IBOutlet weak var enabledSwitch: UISwitch!
    @IBOutlet weak var logModeLabel: UILabel!
    @IBOutlet weak var logModeDescriptionLabel: UILabel!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var tableView: UITableView!

    var configForStream = false
    var devices: [MetaWear] = [] {
        didSet {
            // Create an intersected and sorted array of sensors to configure
            var sensorsConfigMap: [String: SensorConfig] = [:]
            for device in devices {
                for sensorConfig in SensorConfig.onDevice(device) {
                    if sensorsConfigMap[sensorConfig.name] == nil {
                        sensorsConfigMap[sensorConfig.name] = sensorConfig
                    } else {
                        sensorsConfigMap[sensorConfig.name] = sensorsConfigMap[sensorConfig.name]!.combineWith(sensorConfig)
                    }
                }
            }
            sensorsConfigs = Array(sensorsConfigMap.values).sorted { a, b -> Bool in
                a.name.compare(b.name) == .orderedAscending
            }
            sensorsConfigs.forEach { $0.selectedIdx = Constants.isTracker ? 2 : nil }
        }
    }
    var sensorsConfigs: [SensorConfig] = []
    var visibleSensorsConfigs: [SensorConfig] = []
    //var shipment: Shipment?

    var hud: MBProgressHUD?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startButton.backgroundColor = Constants.buttonColor
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        updateVisibleSensors()
        startButton.isEnabled = Constants.isTracker
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destinationNav = segue.destination as? UINavigationController {
            if let destination = destinationNav.viewControllers.first as? StreamTableViewController {
                destination.startStream(devices)
            }
        }
    }
    
    // MARK: - Table view data source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return visibleSensorsConfigs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let config = visibleSensorsConfigs[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: config.rangeValues == nil ? "ConfigCell" : "ConfigRangeCell", for: indexPath) as! ConfigTableViewCell
        // Configure the cell...
        cell.config = config
        cell.delegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "SENSORS"
    }
    
    @IBAction func loggingModeChanged(_ sender: UISwitch) {
        configForStream = !sender.isOn
        if sender.isOn {
            UIView.animate(withDuration: 0.25) {
                self.checkImage.alpha = 1.0
                self.xImage.alpha = 0.0
                self.logModeDescriptionLabel.text = "Data logged to MetaWear, download later with any MetaBase App"
                self.logModeLabel.text = "Logging"
            }
        } else {
            UIView.animate(withDuration: 0.25) {
                self.checkImage.alpha = 0.0
                self.xImage.alpha = 1.0
                self.logModeDescriptionLabel.text = "Data streamed directly to iOS device."
                self.logModeLabel.text = "Streaming"
            }
        }
    }
    
    @IBAction func helpPressed(_ sender: AnyObject) {
        let alertController = UIAlertController(title: "Help", message: "Select which sensors you want to enable and how fast to sample data from them.  Keep in mind that the list displays all sensors that at least one board can use therefore not all boards can use an enabled sensor.", preferredStyle: UIAlertController.Style.alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true)
    }
    
    @IBAction func startPressed(_ sender: AnyObject) {
        if configForStream {
            // One final frequency check
            let totalPackets = sensorsConfigs.reduce(0.0) { $0 + $1.packetsPerSecond }
            if totalPackets > MAX_PACKETS_SEC {
                showStreamFrequencyError()
            } else {
                // Let the stream controller start and handle the actual streaming
                performSegue(withIdentifier: "StreamStatus", sender: nil)
            }
        } else {
            #if TRACKER
                syncShipment()
            #else
                startLogging()
            #endif
        }
    }
    
    func startLogging(shipmentId: String? = nil) {
        hud = MBProgressHUD.showAdded(to: UIApplication.shared.keyWindow!, animated: true)
        hud!.label.text = "Programming..."
        var tasks: [Task<MetaWear>] = []
        for device in devices {
            var disconnectTask: Task<MetaWear>?
            tasks.append(device.connectAndSetup().continueOnSuccessWithTask(device.apiAccessExecutor) { t -> Task<MetaWear> in
                device.clearAndReset()
                return t
            }.continueWithTask { _ in
                return device.connectAndSetup()
            }.continueOnSuccessWithTask(device.apiAccessExecutor) { t -> Task<Int32> in
                disconnectTask = t
                return CommandLog.start(device, configs: SensorConfig.sensors)
            }.continueOnSuccessWithTask(device.apiAccessExecutor) { _ -> Task<MetaWear> in
                mbl_mw_debug_disconnect(device.board)
                return disconnectTask!
            })
        }
        Task.whenAll(tasks).continueWith { t in
            if let agg = t.error as? AggregateError {
                agg.errors.forEach { print($0.localizedDescription) }
            }
            self.startLoggingFinishedWithError(t.error)
        }
    }
    
    func startLoggingFinishedWithError(_ error: Error?) {
        DispatchQueue.main.async {
            var title = "SUCCESS"
            var message = "The sensors have been configured and started logging data."
            var OKAction = UIAlertAction(title: "OK", style: .default) { (action) in
                let _ = self.navigationController?.popToRootViewController(animated: true)
            }
            if let error = error {
                title = "ERROR"
                message = error.localizedDescription + "  Please try again."
                OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            }
            let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
            alertController.addAction(OKAction)
            self.present(alertController, animated: true)
            self.hud?.hide(animated: true)
        }
    }
    
    func updateVisibleSensors() {
        var hiddenSensors: Set<String> = []
        for sensorsConfig in sensorsConfigs {
            if sensorsConfig.selectedIdx != nil {
                for exclude in sensorsConfig.exclusiveWith {
                    hiddenSensors.insert(exclude)
                }
            }
        }
        let newVisibleSensors = sensorsConfigs.filter {
            !hiddenSensors.contains($0.name)
        }
        if visibleSensorsConfigs != newVisibleSensors {
            visibleSensorsConfigs = newVisibleSensors
            tableView.reloadSections([0], with: .automatic)
        }
    }

    func configTableViewCellCanChangeFreq(_ cell: ConfigTableViewCell) -> Bool {
        guard configForStream else {
            return true
        }
        // Reject if streaming can't handle this much speed
        let totalPackets = sensorsConfigs.reduce(0.0) { $0 + $1.packetsPerSecond }
        if totalPackets > MAX_PACKETS_SEC {
            // Inform the user of the problem
            showStreamFrequencyError()
            return false
        }
        return true
    }
    
    func showStreamFrequencyError() {
        let alertController = UIAlertController(title: "Error", message: "Total transmission frequency cannot exceed 100Hz over a BLE connection.", preferredStyle: UIAlertController.Style.alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true)
    }
    
    func configTableViewCellEnableChanged(_ cell: ConfigTableViewCell) {
        if let changedConfig = cell.config {
            if changedConfig.selectedIdx != nil {
                // Make sure we're allowed to active this
                for exclusiveName in changedConfig.exclusiveWith {
                    for sensorConfig in sensorsConfigs {
                        if sensorConfig.name.caseInsensitiveCompare(exclusiveName) == .orderedSame {
                            if sensorConfig.selectedIdx != nil {
                                // Reject this attempted enable
                                cell.disableSensor()
                                return
                            }
                        }
                    }
                }
                // Reject if streaming can't handle this much speed
                if configForStream {
                    let totalPackets = sensorsConfigs.reduce(0.0) { $0 + $1.packetsPerSecond }
                    if totalPackets > MAX_PACKETS_SEC {
                        // Reject this attempted enable
                        cell.disableSensor()
                        // Inform the user of the problem
                        showStreamFrequencyError()
                        return
                    }
                }
            }
            updateVisibleSensors()
        }
        startButton.isEnabled = sensorsConfigs.contains { $0.selectedIdx != nil }
    }
}

/*extension ConfigTableViewController: PFLogInViewControllerDelegate {
    func syncShipment() {
        guard let user = PFUser.current() else {
            let logInViewController = PFLogInViewController()
            logInViewController.delegate = self
            logInViewController.logInView?.signUpButton?.removeTarget(nil, action: nil, for: .allEvents)
            logInViewController.logInView?.signUpButton?.addTarget(self, action: #selector(self.signUpPressed), for: .touchUpInside)
            logInViewController.logInView?.logo = UIImageView(image: UIImage(named: "Logo"))
            self.present(logInViewController, animated: true)
            return
        }
        hud = MBProgressHUD.showAdded(to: UIApplication.shared.keyWindow!, animated: true)
        hud!.label.text = "Saving..."
        
        shipment!.acl = PFACL(user: user)
        shipment!.saveInBackground { (success, error) in
            if success {
                self.hud!.label.text = "Programming..."
                self.startLogging(shipmentId: self.shipment!.objectId!)
            } else {
                self.hud?.hide(animated: false)
                let alertController = UIAlertController(title: "Error", message: error?.localizedDescription ?? "Cannot save shipment, check network and try again", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alertController, animated: true)
            }
        }
    }
    
    @objc func signUpPressed() {
        // Dismiss the ParseViewController
        dismiss(animated: false) {
            UIApplication.shared.open(URL(string:"https://metacloud.mbientlab.com/login.html#signup")!)
        }
    }
    
    func log(_ logInController: PFLogInViewController, didLogIn user: PFUser) {
        dismiss(animated: true) {
            self.syncShipment()
        }
    }
    
    func log(_ logInController: PFLogInViewController, didFailToLogInWithError error: Error?) {
        // Clear password on fail
        logInController.logInView?.passwordField?.text = ""
    }
}*/
