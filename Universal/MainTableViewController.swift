//
//  MainTableViewController.swift
//  MetaBase
//
//  Created by Stephen Schiffli on 2/5/16.
//  Copyright © 2016 MBIENTLAB, INC. All rights reserved.
//

import UIKit
import RMessage
import MetaWear
import MetaWearCpp
import CoreBluetooth

class MainTableViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var groupTabBarButton: UIBarButtonItem!
    @IBOutlet weak var groupSelectionButton: UIButton!
    @IBOutlet weak var groupButtonHeight: NSLayoutConstraint!
    
    var savedMetaWears = SavedMetaWears()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        groupButtonHeight.constant = 0
        #if TRACKER
            navigationItem.title = "MetaTracker"
        #endif
        savedMetaWears.load(self).continueWith(.mainThread) { _ in
            self.tableView.reloadData()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard UserDefaults.standard.string(forKey: "com.mbientlab.MetaBase.walkthroughShown") != nil else {
            UserDefaults.standard.set("yes", forKey: "com.mbientlab.MetaBase.walkthroughShown")
            performSegue(withIdentifier: "ShowTutorial", sender: nil)
            return
        }
        
        MetaWearScanner.shared.didUpdateState = { [weak self] central in
            DispatchQueue.main.async {
                self?.updateUI(central)
            }
        }
        savedMetaWears.startRssiTracking()
        tableView.reloadData()
    }
    
    func updateUI(_ central: CBCentralManager) {
        // Pop up bluetooth errors!
        switch central.state {
        case .unsupported:
            RMessage.showNotification(withTitle: "Bluetooth Error", subtitle: "Device doesn't support the Bluetooth Low Energy.", type: .error, customTypeName: nil, callback: nil)
        case .unauthorized:
            RMessage.showNotification(withTitle: "Bluetooth Error", subtitle: "The application is not authorized to use the Bluetooth Low Energy.", type: .error, customTypeName: nil, callback: nil)
        case .poweredOff:
            RMessage.showNotification(withTitle: "Bluetooth Error", subtitle: "Bluetooth is currently powered off.  Please enable it in settings.", type: .error, customTypeName: nil, callback: nil)
        default:
            break
        }
    }
    
    @IBAction func groupTabBarPressed(_ sender: Any) {
        let editing = !tableView.isEditing
        tableView.setEditing(editing, animated: true)
        groupTabBarButton.title = editing ? "Cancel" : "Group"
        groupSelectionButton.isEnabled = false
        UIView.animate(withDuration: 0.4) {
            self.groupButtonHeight.constant = editing ? 75 : 0
            self.view.layoutIfNeeded()
        }
    }
    
    @IBAction func groupSelectionPressed(_ sender: Any) {
        if let paths = tableView.indexPathsForSelectedRows {
            let indexes = paths.map { $0.row }
            showGroupNameInput {
                if $0 != nil {
                    self.groupTabBarPressed(self.groupTabBarButton)
                    self.savedMetaWears.groupDevices(name: $0!, indexes: indexes)
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? ConnectTableViewController {
            let blacklist = savedMetaWears.groups.flatMap { $0.devices } + savedMetaWears.devices
            destination.startScan(delegate: self, scanner: savedMetaWears.scanner, showConfigured: true, showMetaBoots: true, blacklist: blacklist)
        } else if let destination = segue.destination as? DeviceDetailViewController {
            if let device = sender as? MetaWear {
                destination.setDevices([device], name: device.metadata.name, isRecording: device.isConfigured)
            } else if let group = sender as? MetaWearGroup {
                let isRecording = group.devices.contains { $0.isConfigured }
                destination.setDevices(group.devices, name: group.name, isRecording: isRecording)
            }
        }
    }
    
    @IBAction func unwindToMainTableViewController(segue: UIStoryboardSegue) {
    }
}

extension MainTableViewController: ConnectTableViewDelegate {
    func connectController(_ controller: ConnectTableViewController, didSelectDevice device: MetaWear) {
        savedMetaWears.addDevice(device)
        navigationController?.popViewController(animated: true)
    }
    
    func connectControllerDidCancel(_ controller: ConnectTableViewController) {
        navigationController?.popViewController(animated: true)
    }
}

extension MainTableViewController: SavedMetaWearsDelegate {
    func savedMetaWears(_ savedMetaWears: SavedMetaWears, didAddDevicesAt indexes: [Int]) {
        DispatchQueue.main.async {
            self.tableView.insertRows(at: indexes.map { IndexPath(row: $0, section: 0) }, with: .automatic)
        }
    }
    
    func savedMetaWears(_ savedMetaWears: SavedMetaWears, didRemoveDevicesAt indexes: [Int]) {
        DispatchQueue.main.async {
            self.tableView.deleteRows(at: indexes.map { IndexPath(row: $0, section: 0) }, with: .automatic)
        }
    }
    
    func savedMetaWears(_ savedMetaWears: SavedMetaWears, didAddGroupAt idx: Int, removeDevicesAt indexes: [Int]) {
        DispatchQueue.main.async {
            self.tableView.beginUpdates()
            self.tableView.insertRows(at: [IndexPath(row: idx, section: 1)], with: .automatic)
            self.tableView.deleteRows(at: indexes.map { IndexPath(row: $0, section: 0) }, with: .automatic)
            self.tableView.endUpdates()
        }
    }
    
    func savedMetaWears(_ savedMetaWears: SavedMetaWears, didRemoveGroupAt idx: Int, addDevicesAt indexes: [Int]) {
        DispatchQueue.main.async {
            self.tableView.beginUpdates()
            self.tableView.deleteRows(at: [IndexPath(row: idx, section: 1)], with: .automatic)
            self.tableView.insertRows(at: indexes.map { IndexPath(row: $0, section: 0) }, with: .automatic)
            self.tableView.endUpdates()
        }
    }
}

extension MainTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard !tableView.isEditing else {
            groupSelectionButton.isEnabled = tableView.indexPathsForSelectedRows?.count ?? 0 > 1
            return
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard !tableView.isEditing else {
            groupSelectionButton.isEnabled = tableView.indexPathsForSelectedRows?.count ?? 0 > 1
            return
        }
        tableView.deselectRow(at: indexPath, animated: false)
        if indexPath.section == 0 {
            if indexPath.row == savedMetaWears.devices.count {
                performSegue(withIdentifier: "ShowScanScreen", sender: nil)
            } else {
                performSegue(withIdentifier: "ShowDetailScreen", sender: savedMetaWears.devices[indexPath.row])
            }
        } else {
            performSegue(withIdentifier: "ShowDetailScreen", sender: savedMetaWears.groups[indexPath.row])
        }
    }
    
    func canEditRow(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> Bool {
        let section1AndEditing = (indexPath.section == 1) && (tableView.isEditing)
        let section0LastRow = (indexPath.section == 0) && (indexPath.row == savedMetaWears.devices.count)
        return !section1AndEditing && !section0LastRow
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if tableView.isEditing && !canEditRow(tableView, willSelectRowAt: indexPath) {
            return nil
        }
        return indexPath
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return canEditRow(tableView, willSelectRowAt: indexPath)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if indexPath.section == 0 {
                savedMetaWears.removeDevice(indexPath.row)
            } else {
                savedMetaWears.ungroup(indexPath.row)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return indexPath.section == 0 ? "Delete" : "Ungroup"
    }
}

extension MainTableViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "MY DEVICES" : "MY GROUPS"
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? savedMetaWears.devices.count + 1 : savedMetaWears.groups.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        if indexPath.section == 0 {
            let device = indexPath.row < savedMetaWears.devices.count ? savedMetaWears.devices[indexPath.row] : nil
            cell = tableView.dequeueReusableCell(withIdentifier: device == nil ? "AddDeviceCell" : "DeviceCell", for: indexPath)
            if let device = device {
                (cell as! MainTableViewCell).device = device
            }
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: "GroupCell", for: indexPath)
            let group = savedMetaWears.groups[indexPath.row]
            (cell as! GroupTableViewCell).devices = group.devices
            (cell as! GroupTableViewCell).nameLabel.text = group.name
        }
        return cell
    }
}
