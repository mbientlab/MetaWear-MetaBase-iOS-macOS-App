//
//  ConnectTableViewController.swift
//  MetaBase
//
//  Created by Stephen Schiffli on 2/5/16.
//  Copyright © 2016 MBIENTLAB, INC. All rights reserved.
//

import UIKit
import MBProgressHUD
import CoreBluetooth
import MetaWear


protocol ConnectTableViewDelegate: class {
    func connectController(_ controller: ConnectTableViewController, didSelectDevice device: MetaWear)
    func connectControllerDidCancel(_ controller: ConnectTableViewController)
}

class ConnectTableViewController: UIViewController {
    @IBOutlet weak var lookingLabel: UILabel!
    @IBOutlet weak var scanActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    
    weak var delegate: ConnectTableViewDelegate?
    var hud: MBProgressHUD?
    var scannerModel: ScannerModel!
    var isScanning = false {
        didSet {
            DispatchQueue.main.async {
                self.isScanning
                    ? self.scanActivityIndicator.startAnimating()
                    : self.scanActivityIndicator.stopAnimating()
            }
            scannerModel?.isScanning = isScanning
        }
    }
    
    func startScan(delegate: ConnectTableViewDelegate, scanner: MetaWearScanner, showConfigured: Bool, showMetaBoots: Bool, blacklist: [MetaWear]) {
        self.delegate = delegate
        scannerModel = ScannerModel(delegate: self, scanner: scanner) {
            guard !$0.isMetaBoot || showMetaBoots,
                !$0.isConfigured || showConfigured,
                !blacklist.contains($0) else {
                return false
            }
            return true
        }
        isScanning = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        isScanning = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isScanning = false
    }
    
    @IBAction func cancelPressed(_ sender: Any) {
        delegate?.connectControllerDidCancel(self)
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? DiagnosticViewController {
            destination.device = (sender as! MetaWear)
        }
    }
}

extension ConnectTableViewController: UITableViewDelegate {
    
}

extension ConnectTableViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        lookingLabel.isHidden = scannerModel.items.count > 0
        return scannerModel.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ConnectCell", for: indexPath) as! ConnectTableViewCell
        cell.model = scannerModel.items[indexPath.row]
        return cell
    }
}

extension ConnectTableViewController: ScannerModelDelegate {
    func scannerModel(_ scannerModel: ScannerModel, didAddItemAt idx: Int) {
        let device = scannerModel.items[idx].device
        if let data = try? Data(contentsOf: device.uniqueUrl) {
            device.deserialize([UInt8](data))
        }
        let indexPath = IndexPath(row: idx, section: 0)
        tableView.insertRows(at: [indexPath], with: .automatic)
    }
    
    func scannerModel(_ scannerModel: ScannerModel, confirmBlinkingItem item: ScannerModelItem, callback: @escaping (Bool) -> Void) {
        guard !item.device.isMetaBoot else {
            callback(false)
            performSegue(withIdentifier: "ShowDiagnostic", sender: item.device)
            return
        }
        showNameInputAlert(currentName: item.device.metadata.name) { name in
            callback(name != nil)
            if let name = name {
                item.device.metadata.name = name
                self.delegate?.connectController(self, didSelectDevice: item.device)
            }
        }
    }
    
    func scannerModel(_ scannerModel: ScannerModel, errorDidOccur error: Error) {
        showOKAlert("Error", message: error.localizedDescription)
    }
}
