//
//  NewShipmentViewController.swift
//  MetaBase
//
//  Created by Stephen Schiffli on 11/2/17.
//  Copyright © 2017 MBIENTLAB, INC. All rights reserved.
//

import UIKit
import MetaWear
import MBProgressHUD
//import Parse

/*class NewShipmentViewController: UIViewController {
    @IBOutlet weak var trackingTextField: UITextField!
    @IBOutlet weak var descriptionTextField: UITextField!
    @IBOutlet weak var startingTextField: UITextField!
    @IBOutlet weak var endingTextField: UITextField!
    @IBOutlet weak var methodTextField: UITextField!
    @IBOutlet weak var nextButton: UIBarButtonItem!
    
    var devices: [MetaWear] = []
    var shipment = Shipment()

    @IBAction func nextPressed(_ sender: Any) {
        shipment.state = 0
        shipment.trackingNumber = trackingTextField.text!
        shipment.shipmentDescription = descriptionTextField.text!
        shipment.startingLocation = startingTextField.text!
        shipment.endingLocation = endingTextField.text!
        shipment.shipmentMethod = methodTextField.text!
        performSegue(withIdentifier: "Config", sender: nil)
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? ConfigTableViewController {
            destination.devices = devices
            destination.configForStream = false
            destination.shipment = shipment
        }
    }
}

extension NewShipmentViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let nextTage = textField.tag + 1;
        // Try to find next responder
        if let nextResponder = textField.superview?.viewWithTag(nextTage) {
            // Found next responder, so set it.
            nextResponder.becomeFirstResponder()
        } else {
            // Not found, so must be and the end
            nextPressed(nextButton)
        }
        return false // We do not want UITextField to insert line-breaks.
    }
}*/
