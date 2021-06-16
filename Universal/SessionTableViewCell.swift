//
//  SessionTableViewCell.swift
//  MetaBase
//
//  Created by Stephen Schiffli on 2/14/18.
//  Copyright © 2018 MBIENTLAB, INC. All rights reserved.
//

import UIKit
//import Parse
//import FirebaseAnalytics


class SessionTableViewCell: UITableViewCell {
    @IBOutlet weak var mainLabel: UILabel!
    @IBOutlet weak var timeAgoLabel: UILabel!
    @IBOutlet weak var cloudButton: UIButton!
    @IBOutlet weak var cloudActivity: UIActivityIndicatorView!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var shareActivity: UIActivityIndicatorView!
    
    var parentController: UIViewController!
    var models: [SessionModel]! {
        didSet {
            mainLabel.text = models.first!.note
            timeAgoLabel.text = models.first!.started.timeAgo()
        }
    }
    
    @IBAction func sharePressed(_ sender: Any) {
        shareButton.isEnabled = false
        shareActivity.startAnimating()
        // The UIActivityViewController taks a long time to setup so we do this on a background thread
        DispatchQueue.global().async {
            let files = self.models.flatMap { $0.files.map { $0.csvFilename.documentDirectoryUrl } }
            let activity = UIActivityViewController(activityItems: files, applicationActivities: nil)
            OperationQueue.main.addOperation {
                self.shareButton.isEnabled = true
                self.shareActivity.stopAnimating()
                if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.pad) {
                    if let popoverController = activity.popoverPresentationController {
                        popoverController.sourceRect = self.parentController.view.bounds
                        popoverController.sourceView = self.parentController.view
                        popoverController.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
                    }
                }
                self.parentController.present(activity, animated: true)
            }
        }
    }
    
    /*@IBAction func cloudPressed(_ sender: Any) {
        // One time pop up event for explaning that cloud services are paid
        guard UserDefaults.standard.string(forKey: "com.mbientlab.MetaBase.cloudMessageShown") != nil else {
            UserDefaults.standard.set("yes", forKey: "com.mbientlab.MetaBase.cloudMessageShown")
            let alertController = UIAlertController(title: Constants.cloudName, message: "\(Constants.cloudName) is a service offered by MbientLab that saves your sensor data to the cloud and provides a dashboard to interact with the synced data.\n\nUsing this service requires a monthly subscription.", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default) { (action) in
                self.cloudPressed(sender)
            })
            parentController.present(alertController, animated: true)
            return
        }
        
        // Present proper cloud options
        let alertController = UIAlertController(title: Constants.cloudName, message: nil, preferredStyle: .actionSheet)
        if let user = PFUser.current() {
            alertController.addAction(UIAlertAction(title: "Logout \(user.username ?? "UNKNOWN")", style: .destructive) { (action) in
                PFUser.logOut()
            })
            alertController.addAction(UIAlertAction(title: "Sync", style: .default) { (action) in
                self.doSync()
            })
        } else {
            alertController.addAction(UIAlertAction(title: "Login", style: .default) { (action) in
                self.showLogin()
            })
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        parentController.present(alertController, animated: true)
    }
    
    @objc func signUpPressed() {
        // Dismiss the ParseViewController
        parentController.dismiss(animated: false) {
            UIApplication.shared.open(URL(string:"https://metacloud.mbientlab.com/login.html#signup")!)
        }
    }
    
    func doSync() {
        guard let user = PFUser.current() else {
            self.showLogin()
            return
        }
        // No-frills metabase upload
        self.syncToCloud(user, location: nil, isComplete: false)
    }
    
    func syncToCloud(_ user: PFUser, location: PFGeoPoint?, isComplete: Bool) {
        cloudButton.isEnabled = false
        cloudActivity.startAnimating()
        
        let objects: [PFObject] = models.map { Session.from(model: $0, user: user, location: location) }
        PFObject.saveAll(inBackground: objects) { (success, error) in
            self.cloudButton.isEnabled = true
            self.cloudActivity.stopAnimating()
            var alertController: UIAlertController?
            if let error = error {
                alertController = UIAlertController(title: "ERROR", message: "Failed to Upload Data.\n\(error.localizedDescription)", preferredStyle: UIAlertController.Style.alert)
                alertController!.addAction(UIAlertAction(title: "OK", style: .default))
            } else {
                Analytics.logEvent("sync_metacloud", parameters: nil)
                alertController = UIAlertController(title: "Success", message: "Uploaded \(user.username ?? "UNKNOWN")'s data to \(Constants.cloudName)", preferredStyle: UIAlertController.Style.alert)
                alertController!.addAction(UIAlertAction(title: "OK", style: .default))
            }
            self.parentController.present(alertController!, animated: true)
        }
    }
    
    func showLogin() {
        DispatchQueue.main.async {
            let logInViewController = PFLogInViewController()
            logInViewController.delegate = self
            logInViewController.logInView?.signUpButton?.removeTarget(nil, action: nil, for: .allEvents)
            logInViewController.logInView?.signUpButton?.addTarget(self, action: #selector(self.signUpPressed), for: .touchUpInside)
            logInViewController.logInView?.logo = UIImageView(image: UIImage(named: "Logo"))
            self.parentController.present(logInViewController, animated: true)
        }
    }*/
}


/*extension SessionTableViewCell: PFLogInViewControllerDelegate {
    func log(_ logInController: PFLogInViewController, didLogIn user: PFUser) {
        parentController.dismiss(animated: true) {
            self.cloudPressed(self.cloudButton)
        }
    }
    func log(_ logInController: PFLogInViewController, didFailToLogInWithError error: Error?) {
        // Clear password on fail
        logInController.logInView?.passwordField?.text = ""
    }
    func logInViewControllerDidCancelLog(in logInController: PFLogInViewController) {
    }
}*/
