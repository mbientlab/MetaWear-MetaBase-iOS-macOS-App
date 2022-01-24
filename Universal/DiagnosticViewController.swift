//
//  DiagnosticViewController.swift
//  MetaBase
//
//  Created by Stephen Schiffli on 10/5/17.
//  Copyright © 2017 MBIENTLAB, INC. All rights reserved.
//

import UIKit
import MessageUI
import MBProgressHUD
import MetaWear
import MetaWearCpp
import BoltsSwift
//import FirebaseAnalytics


class DiagnosticViewController: UIViewController {
    @IBOutlet weak var macLabel: UILabel!
    @IBOutlet weak var modelLabel: UILabel!
    @IBOutlet weak var modelNumberLabel: UILabel!
    @IBOutlet weak var firmwareLabel: UILabel!
    @IBOutlet weak var hardwareLabel: UILabel!
    @IBOutlet weak var serialNumberLabel: UILabel!
    @IBOutlet weak var manufactureLabel: UILabel!
    @IBOutlet weak var rssiLabel: UILabel!
    @IBOutlet weak var batteryLabel: UILabel!
    @IBOutlet weak var runDiagnosticButton: UIButton!
    @IBOutlet weak var advancedButton: UIBarButtonItem!
    @IBOutlet weak var buzzFlashButton: UIButton!
    
    var device: MetaWear!
    var id: UUID!
    let scanner = MetaWearScanner()
    var connectionManager: ConnectionManager!
    var hud: MBProgressHUD!
    var picker: UIDocumentPickerViewController?
    var diagnosticData: DiagnosticData?
    var didConnect = false
    var skipConnectOnNext = false
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard !skipConnectOnNext else {
            skipConnectOnNext = false
            return
        }
        // Ensure we are disconnected so our new scanner can find it and
        // do a fresh connection and discovery
        device.cancelConnection()
        id = device.peripheral.identifier
        
        hud = MBProgressHUD.showAdded(to: UIApplication.shared.keyWindow!, animated: true)
        hud.removeFromSuperViewOnHide = false
        hud.label.text = "Scanning..."
        
        scanAndConnect()
    }
    
    func scanAndConnect() {
        var found = false
        scanner.startScan(allowDuplicates: false) { device in
            guard device.peripheral.identifier == self.id else {
                return
            }
            found = true
            self.scanner.stopScan()
            self.device = device
            DispatchQueue.main.async {
                self.buzzFlashButton.isEnabled = device.isMetaBoot
                self.runDiagnosticButton.isEnabled = device.isMetaBoot
                self.connectionManager = ConnectionManager(device, delegate: self)
                self.connectDevice()
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
            if !found {
                self.scanner.stopScan()
                self.hud.hide(animated: true)
                self.showOKAlert("Error", message: "Could not find device, please check battery and try again.") { _ in
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
    }

    func connectDevice() {
        DispatchQueue.main.async {
            self.hud.show(animated: true)
            self.hud.label.text = "Connecting..."
            self.advancedButton.isEnabled = false
            self.didConnect = false
            self.connectionManager.connectDevice(checkForUpdate: true)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
                if !self.didConnect {
                    self.connectionManager.disconnectDevice()
                    self.hud.hide(animated: true)
                    self.showOKAlert("Error", message: "Could not connect to device, please check battery and try again.") { _ in
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            }
        }
    }
    
    func updateUI() {
        guard let diagnosticData = diagnosticData else {
            return
        }
        macLabel.text = diagnosticData.mac
        modelLabel.text = diagnosticData.model
        modelNumberLabel.text = diagnosticData.modelNumber
        firmwareLabel.text = diagnosticData.firmware
        hardwareLabel.text = diagnosticData.hardware
        serialNumberLabel.text = diagnosticData.serialNumber
        manufactureLabel.text = diagnosticData.manufacturer
        rssiLabel.text = diagnosticData.rssi
        batteryLabel.text = diagnosticData.battery
    }
    
    func metaBootWarning() {
        DispatchQueue.main.async {
            self.showOKAlert("Warning", message: "Your device is in MetaBoot mode. Typically, the board will reset itself back to normal operation after a minute.\n\nIn the case where it is stuck in MetaBoot mode, you can manually return the board to normal by initiating a firmware update.")
        }
    }
    
    @IBAction func runDiagnosticPressed(_ sender: Any) {
        guard MFMailComposeViewController.canSendMail() else {
            showOKAlert("Error", message: "E-Mail services are not available")
            return
        }
        guard let diagnosticData = diagnosticData else {
            showOKAlert("Error", message: "Data not ready, please restart app and try again")
            return
        }
        guard let prettyJsonData = diagnosticData.json.data(using: .utf8) else {
            showOKAlert("Error", message: "Data not valid, please restart app and try again")
            return
        }
        let composeVC = MFMailComposeViewController()
        composeVC.mailComposeDelegate = self
        composeVC.setToRecipients(["name@gmail.com"])
        composeVC.setSubject("[MbientLab Diagnostic] MetaSensor \(diagnosticData.mac)")
        composeVC.addAttachmentData(prettyJsonData, mimeType: "application/json", fileName: "diagnostic_\(diagnosticData.mac.replacingOccurrences(of: ":", with: ""))_\(diagnosticData.os).json")
        composeVC.setMessageBody("<Add additional information here>", isHTML: false)
        // Present the view controller modally.
        present(composeVC, animated: true, completion: nil)
        //Analytics.logEvent("run_diagnostic", parameters: [
        //    "mac": device.mac ?? "FF:FF:FF:FF:FF:FF"
        //])
    }
    
    @IBAction func buzzCoinMotor(_ sender: Any) {
        device.connectAndSetup().continueOnSuccessWithTask { t -> Task<MetaWear> in
            // LED Feedback to indicate success
            self.device.flashLED(color: .blue, intensity: 1.0, _repeat: 4)
            // Pulse of the haptic for testing
            mbl_mw_haptic_start_motor(self.device.board, 100, 500)
            return t
        }
    }
    
    @IBAction func updateFirmwarePressed(_ sender: Any) {
        connectionManager.updateFirmware()
    }

    @IBAction func haltAllLogging(_ sender: Any) {
        device.connectAndSetup().continueOnSuccessWithTask { t -> Task<MetaWear> in

            let board = self.device.board
            mbl_mw_logging_stop(board)
            mbl_mw_sensor_fusion_stop(board)
            mbl_mw_acc_stop(board)

            if mbl_mw_metawearboard_lookup_module(board, MBL_MW_MODULE_GYRO) == MBL_MW_MODULE_GYRO_TYPE_BMI160 {
                mbl_mw_gyro_bmi160_stop(board)
            } else {
                mbl_mw_gyro_bmi270_stop(board)
            }

            if mbl_mw_metawearboard_lookup_module(board, MBL_MW_MODULE_MAGNETOMETER) != MBL_MW_MODULE_TYPE_NA {
                mbl_mw_mag_bmm150_stop(board)
            }

            if mbl_mw_metawearboard_lookup_module(board, MBL_MW_MODULE_AMBIENT_LIGHT) != MBL_MW_MODULE_TYPE_NA {
                mbl_mw_als_ltr329_stop(board)
            }
            self.device.flashLED(color: .purple, intensity: 1.0, _repeat: 2)
            return t
        }
    }
    
    @IBAction func advancedPressed(_ sender: Any) {
        let alertController = UIAlertController(title: "Advanced Options", message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "DFU from File", style: .default) { _ in
            self.getFirmwareFile()
        })
        alertController.addAction(UIAlertAction(title: "DFU from Version", style: .default) { _ in
            self.getFirmwareVersion()
        })
        if !device.isMetaBoot {
            alertController.addAction(UIAlertAction(title: "Put to Sleep", style: .default) { _ in
                self.putToSleep()
            })
            alertController.addAction(UIAlertAction(title: "Reset", style: .default) { _ in
                self.resetDevice()
            })
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alertController, animated: true)
    }
    
    func resetDevice() {
        DispatchQueue.main.async {
            self.hud.show(animated: true)
            self.hud.label.text = "Resetting..."
        }
        device.connectAndSetup().continueOnSuccessWithTask { t -> Task<MetaWear> in
            self.device.clearAndReset()
            return t
        }.continueWith(.mainThread) { t in
            guard !t.faulted else {
                self.hud.hide(animated: true)
                self.showOKAlert("Error", message: t.error!.localizedDescription) { _ in
                    self.navigationController?.popViewController(animated: true)
                }
                return
            }
            self.connectDevice()
        }
    }
    
    func putToSleep() {
        DispatchQueue.main.async {
            self.hud.show(animated: true)
            self.hud.label.text = "Sleeping..."
        }
        device.connectAndSetup().continueOnSuccessWithTask(device.apiAccessExecutor) { t -> Task<MetaWear> in
            mbl_mw_debug_enable_power_save(self.device.board)
            self.device.clearAndReset()
            return t
        }.continueWith(.mainThread) { t in
            self.hud.hide(animated: true)
            self.showOKAlert(t.error != nil ? "Error" : "Success",
                             message:t.error != nil
                                ? t.error!.localizedDescription
                                : "Board in ultra low power sleep state.  To wake, you can press the button, reinsert the coin cell battery, or connect a usb charger.")
            { _ in
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    func getFirmwareFile() {
        picker = UIDocumentPickerViewController(documentTypes: ["com.pkware.zip-archive", "com.apple.macbinary-​archive"], in: .import)
        picker!.delegate = self
        skipConnectOnNext = true
        present(picker!, animated: true)
    }
    
    func getFirmwareVersion() {
        let alert = UIAlertController(title: "Update", message: "Enter firmware version number.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        let updateAction = UIAlertAction(title: "Update", style: .default) { action in
            let textField = alert.textFields![0] as UITextField
            self.updateFirmwareToVersion(textField.text!)
        }
        updateAction.isEnabled = false
        alert.addAction(updateAction)
        alert.addTextField() { textField in
            textField.placeholder = "1.3.6"
            textField.keyboardType = .decimalPad
            NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object: textField, queue: OperationQueue.main) { (notification) in
                updateAction.isEnabled = textField.text!.isValidVersion
            }
        }
        present(alert, animated: true)
    }
    
    func updateFirmwareToVersion(_ version: String) {
        guard let deviceInfo = device.info else {
            showOKAlert("Error", message: "Couldn't find deviceInfo")
            return
        }
        let t = FirmwareServer.getAllFirmwareAsync(hardwareRev: deviceInfo.hardwareRevision,
                                                   modelNumber: deviceInfo.modelNumber)
        

        t.continueWith { t in
            guard let firmwares = t.result else {
                self.showOKAlert("Error", message: t.error?.localizedDescription ?? "Version \(version) not found, please try again.")
                return
            }
            if let firmware = firmwares.first(where: { $0.firmwareRev == version }) {
                self.connectionManager.updateFirmware(firmware)
            } else {
                let t = FirmwareServer.getVersionAsync(hardwareRev: deviceInfo.hardwareRevision,
                                                       modelNumber: deviceInfo.modelNumber,
                                                       firmwareRev: version)
                t.continueWith { t in
                    guard let build = t.result else {
                        self.showOKAlert("Error", message: "Version \(version) not found, please try again.")
                        return
                    }
                    self.showOKCancelAlert("WARNING", message: "Required bootloader cannot be confirmed, be absoutly sure this is a valid version or RISK PERMENT DAMAGE TO METAWEAR") { okay in
                        if okay {
                            self.connectionManager.updateFirmware(build)
                        }
                    }
                }
            }
        }
    }
    
    func updateFirmwareWithFile(_ file: URL) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: "WARNING", message: "Required bootloader cannot be confirmed when choosing a file directly, be absoutely sure this is a valid file or RISK PERMANENT DAMAGE TO METAWEAR", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Update", style: .destructive) { _ in
                let build = FirmwareBuild(hardwareRev: "0", modelNumber: "0", firmwareRev: "0", customUrl: file)
                self.connectionManager.updateFirmware(build)
            })
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            self.present(alertController, animated: true)
        }
    }
}


extension DiagnosticViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if let url = urls.first {
            updateFirmwareWithFile(url)
        }
    }
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    }
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        updateFirmwareWithFile(url)
    }
}

extension String {
    var isValidVersion: Bool {
        let versionRegEx = "^\\d+\\.\\d+\\.\\d+$"
        if let versionTest = NSPredicate(format:"SELF MATCHES %@", versionRegEx) as NSPredicate? {
            return versionTest.evaluate(with: self)
        }
        return false
    }
}

extension DiagnosticViewController: ConnectionManagerDelegate {
    func didConnect(_ device: MetaWear, disconnectTask: Task<MetaWear>?, error: Error?) {
        didConnect = true
        guard error == nil else {
            DispatchQueue.main.async {
                self.hud?.hide(animated: false)
                self.advancedButton.isEnabled = true
            }
            let msg = "Failed to connect to '\(device.name)'. Would you like to try again?\n\n\(error!.localizedDescription)"
            self.showOKCancelAlert("Error", message: msg) { okPressed in
                if okPressed {
                    self.connectDevice()
                } else {
                    self.navigationController?.popViewController(animated: true)
                }
            }
            return
        }
        guard !device.isMetaBoot else {
            metaBootWarning()
            DispatchQueue.main.async {
                self.updateUI();
                self.hud?.hide(animated: true)
                self.advancedButton.isEnabled = true
                self.runDiagnosticButton.isEnabled = false
                self.buzzFlashButton.isEnabled = false
            }
            device.cancelConnection()
            return
        }
        
        device.apiAccessQueue.async {
            let complete = { (charge: UInt8) in
                let batteryLevel = "\(charge)%"
                self.diagnosticData = DiagnosticData(device, batteryLevel: batteryLevel)
                DispatchQueue.main.async {
                    self.updateUI();
                    self.hud?.hide(animated: true)
                    self.advancedButton.isEnabled = true
                    self.runDiagnosticButton.isEnabled = !device.isMetaBoot
                    self.buzzFlashButton.isEnabled = !device.isMetaBoot
                }
                device.cancelConnection()
            }
            // Let them you you have the right device
            device.flashLED(color: .green, intensity: 1.0, _repeat: 5)
            // Read the battery if we can
            if let battery = mbl_mw_settings_get_battery_state_data_signal(device.board) {
                battery.read().continueWith { t in
                    let charge = t.result == nil ? 0 : (t.result!.valueAs() as MblMwBatteryState).charge
                    complete(charge)
                }
            } else {
                complete(0)
            }
        }
    }
    
    func deviceRequestingFirmwareUpdate(_ device: MetaWear, required: Bool, version: String?, performUpdate: @escaping (Bool) -> Void) {
        didConnect = true
        // At this point we are connecting for the first time
        // Flash at most 1 min incase something weird goes on
        device.flashLED(color: .green, intensity: 1.0, _repeat: 60)
        DispatchQueue.main.async {
            self.hud.hide(animated: false)
            var msg = "A new firmware version is available, do you want to update?"
            if required {
                msg = "A new firmware version is required to use this App, do you want to update now?"
            } else if let version = version {
                msg = "New firmware version \(version) is available, do you want to update?"
            }
            let alert = UIAlertController(title: "Firmware Update", message: msg, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Later", style: .cancel) { _ in
                performUpdate(false)
            })
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                performUpdate(true)
            })
            self.present(alert, animated: true)
        }
    }
    
    func deviceFirmwareUpdateStarted(_ device: MetaWear) {
        DispatchQueue.main.async {
            self.hud.show(animated: true)
            self.hud.label.text = "Updating firmware..."
            self.advancedButton.isEnabled = false
        }
    }
    func deviceFirmwareUpdateProgress(_ device: MetaWear, progress: Float) {
        DispatchQueue.main.async {
            if (progress < 1.0) {
                self.hud.mode = .annularDeterminate
                self.hud.progress = progress
            } else {
                self.hud.label.text = "Connecting..."
                self.hud.mode = .indeterminate
            }
        }
    }
    func deviceFirmwareUpdateComplete(_ device: MetaWear, error: Error?) {
        DispatchQueue.main.async {
            self.hud.hide(animated: true)
            self.advancedButton.isEnabled = true
        }
        guard error == nil else {
            let msg = "Failed to update to '\(device.name)'. \n\n\(error!.localizedDescription)"
            self.showOKAlert("Error", message: msg)
            return
        }
        // Try again with the fresh firmware
        scanAndConnect()
    }
}

extension DiagnosticViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        dismiss(animated: true, completion: nil)
    }
}
