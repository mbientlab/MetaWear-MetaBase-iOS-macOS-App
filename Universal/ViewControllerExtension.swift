//
//  ViewControllerExtension.swift
//  MetaBase
//
//  Created by Stephen Schiffli on 1/16/18.
//  Copyright © 2018 MBIENTLAB, INC. All rights reserved.
//

import UIKit

extension UIViewController {
    func showOKAlert(_ title: String, message: String, handler: ((UIAlertAction) -> Void)? = nil) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: handler))
            self.present(alertController, animated: true)
        }
    }
    
    func showOKCancelAlert(_ title: String, message: String, handler: ((Bool) -> Void)? = nil) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                handler?(true)
            })
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                handler?(false)
            })
            self.present(alertController, animated: true)
        }
    }
}
