//
//  FeedbackTableViewController.swift
//  Musical
//
//  Created by Sebastian on 11/28/15.
//  Copyright © 2015 Sebastian. All rights reserved.
//

import UIKit
import MessageUI

class FeedbackTableViewController: UITableViewController, MFMailComposeViewControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if indexPath.section == 0 {
            
            if MFMailComposeViewController.canSendMail() {
                let mail = MFMailComposeViewController()
                mail.navigationBar.tintColor = UIColor.redColor()
                mail.mailComposeDelegate = self
                mail.setToRecipients(["contact@landab.com"])
                mail.setSubject("Musical")
                
                presentViewController(mail, animated: true, completion: nil)
                
            } else {
                // show failure alert
                print("cant send mail")
            }
            
            
        } else {
            
            let url = "itms-apps://itunes.apple.com/app/id1063072083"
            UIApplication.sharedApplication().openURL(NSURL(string: url)!)
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }

}
