//
//  DeviceDetailViewController.swift
//  MetaBase
//
//  Created by Stephen Schiffli on 1/18/18.
//  Copyright © 2018 MBIENTLAB, INC. All rights reserved.
//

import UIKit
import MetaWear
//import Parse
import MBProgressHUD


class DeviceDetailViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var diagnosticButton: UIBarButtonItem!
    @IBOutlet weak var mainButton: UIButton!
    
    var devices: [MetaWear] = []
    var name = ""
    var isRecording = false
    var hud: MBProgressHUD?
    var sessionModels: [[SessionModel]] = []

    func setDevices(_ devices: [MetaWear], name: String, isRecording: Bool) {
        self.name = name
        self.devices = devices
        self.isRecording = isRecording
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = name
        if devices.count > 1 {
            navigationItem.rightBarButtonItem = nil
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        mainButton.setTitle(isRecording ? "DOWNLOAD" : "NEW SESSION", for: .normal)
        // If we have multiple devices, we only whan to show sessions that have been
        // downloaded by all devices in the group. So we find session starting times
        // that each device has.
        let allSessions = devices.map { $0.metadata.sessions }
        let startingDates = allSessions.map { Set($0.map { $0.started }) }
        let allDates = startingDates.reduce(into: startingDates.first) { (result, next) in
            result?.formIntersection(next)
        }?.sorted(by: >)
        #if swift(>=4.1)
            sessionModels = allDates?.map { date in allSessions.compactMap { $0.first { $0.started == date } } } ?? []
        #else
            sessionModels = allDates?.map { date in allSessions.flatMap { $0.first { $0.started == date } } } ?? []
        #endif
        tableView.reloadData()
    }
    
    
    @IBAction func mainButtonPressed(_ sender: Any) {
        performSegue(withIdentifier: isRecording ? "ShowCapture" : "ShowConfig", sender: nil)
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? CaptureViewController {
            destination.startLogCaptures(devices)
        } else if let destination = segue.destination as? DiagnosticViewController {
            destination.device = (sender as! MetaWear)
        } else if let destination = segue.destination as? ConfigTableViewController {
            destination.devices = devices
        }
    }
    
    @IBAction func unwindToDeviceDetailViewController(segue: UIStoryboardSegue) {
    }
}

extension DeviceDetailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 1
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if let removedDate = sessionModels.remove(at: indexPath.row).first?.started {
                for device in devices {
                    if let idx = device.metadata.sessions.index(where: { $0.started == removedDate }) {
                        let session = device.metadata.sessions.remove(at: idx)
                        device.metadata.save()
                        session.files.forEach { try? FileManager.default.removeItem(at: $0.csvFilename.documentDirectoryUrl) }
                    }
                }
            }
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == 0 else {
            tableView.deselectRow(at: indexPath, animated: false)
            return
        }
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: "ShowDiagnostic", sender: devices[indexPath.row])
    }
}

extension DeviceDetailViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "DEVICES" : "SESSIONS"
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? devices.count : sessionModels.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        if indexPath.section == 0 {
            cell = tableView.dequeueReusableCell(withIdentifier: "DeviceDetailCell", for: indexPath)
            (cell as! DeviceDetailTableViewCell).device = devices[indexPath.row]
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: "SessionCell", for: indexPath)
            (cell as! SessionTableViewCell).parentController = self
            (cell as! SessionTableViewCell).models = sessionModels[indexPath.row]
        }
        return cell
    }
}
