//
//  FeedbackTableViewController.swift
//  Musical
//
//  Created by Sebastian on 11/28/15.
//  Copyright © 2015 Sebastian. All rights reserved.
//

import UIKit
import MessageUI
//import Crashlytics

class FeedbackTableViewController: UITableViewController, MFMailComposeViewControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Crashlytics.sharedInstance().crash()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 0 {
            
            if MFMailComposeViewController.canSendMail() {
                let mail = MFMailComposeViewController()
                mail.navigationBar.tintColor = UIColor.red
                mail.mailComposeDelegate = self
                mail.setToRecipients(["contact@landab.com"])
                mail.setSubject("Musical")
                
                present(mail, animated: true, completion: nil)
                
            } else {
                // show failure alert
                print("cant send mail")
            }
            
            
        } else {
            
            let url = "itms-apps://itunes.apple.com/app/id1063072083"
            UIApplication.shared.openURL(URL(string: url)!)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }

}
