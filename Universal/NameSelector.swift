//
//  NameSelector.swift
//  MetaBase
//
//  Created by Stephen Schiffli on 1/18/18.
//  Copyright © 2018 MBIENTLAB, INC. All rights reserved.
//

import UIKit


extension UIViewController {
    func showGroupNameInput(_ callback: @escaping (String?) -> Void) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Name Group", message: "Please provide a name for this MetaWear group.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { action in
                callback(nil)
            })
             alert.addAction(UIAlertAction(title: "OK", style: .default) { action in
                let textField = alert.textFields![0] as UITextField
                callback(textField.text!)
            })
            alert.addTextField() { textField in
                textField.placeholder = "Group Name"
                textField.autocapitalizationType = .words
                textField.autocorrectionType = .no
            }
            self.present(alert, animated: true)
        }
    }
    
    func showSessionNameInput(_ callback: @escaping (String) -> Void) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Name Session", message: "Provide a short name to help you remember the context of this data.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { action in
                let textField = alert.textFields![0] as UITextField
                callback(textField.text!)
            })
            alert.addTextField() { textField in
                textField.placeholder = "Session Name"
            }
            self.present(alert, animated: true)
        }
    }
    
    func showNameInputAlert(currentName: String, _ callback: @escaping (String?) -> Void) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Name Device", message: "Please provide a name for the MetaWear with a blinking green LED.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { action in
                callback(nil)
            })
            let okAction = UIAlertAction(title: "OK", style: .default) { action in
                let textField = alert.textFields![0] as UITextField
                callback(textField.text!)
            }
            alert.addAction(okAction);
            alert.addTextField() { textField in
                if currentName != "MetaWear" {
                    textField.text = currentName
                }
                textField.placeholder = "Device Name"
                textField.autocapitalizationType = .words
                textField.autocorrectionType = .no
                NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object: textField, queue: OperationQueue.main) { (notification) in
                    okAction.isEnabled = textField.text!.isValidName
                }
                okAction.isEnabled = textField.text!.isValidName
            }
            self.present(alert, animated: true)
        }
    }
}

fileprivate let nameCharacterSet = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_- ")
extension String {
    var isValidName: Bool {
        guard !isEmpty else {
            return false
        }
        // Make sure only valid characters
        let badCharacter = unicodeScalars.contains { !nameCharacterSet.contains($0) }
        guard !badCharacter else {
            return false
        }
        guard let encoding = data(using: .ascii) else {
            return false
        }
        return encoding.count <= Constants.maxNameLength
    }
}
