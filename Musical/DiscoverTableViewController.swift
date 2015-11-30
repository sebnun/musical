//
//  DiscoverTableViewController.swift
//  Musical
//
//  Created by Sebastian on 11/28/15.
//  Copyright © 2015 Sebastian. All rights reserved.
//

import UIKit

class DiscoverTableViewController: UITableViewController {
    
    
    let playlists = ["PLFgquLnL59alCl_2TQvOiD5Vgm1hCaGSI", "PLFgquLnL59alW3xmYiWRaoz0oM3H17Lth", "PLFgquLnL59akA2PflFpeQG9L01VFg90wS", "PLDcnymzs18LVXfO_x0Ei0R24qDbVtyy66", "PLH6pfBXQXHECUaIU3bu9rjG2L6Uhl5A2q", "PLvLX2y1VZ-tEmqtENBW39gdozqFCN_WZc", "PLhd1HyMTk3f5yqcPXjLo8qroWJiMMFBSk", "PLFPg_IUxqnZN1odUAOrgMifStf-0VZ-lj", "PLYAYp5OI4lRKUjxyMxpxZvSJsJLJBu0XH", "PLlAUeZBl7BV6lWENNsb78zZrgyzmOBwrq", "PLMcThd22goGZoKIj4VAX4GCoYjoCNLiTC", "PLVXq77mXV53_3HqhCLGv4mz3oVGYd2Aup", "PLWNXn_iQ2yrIE-txPYCsmdmRJv-iSTPsL", "PLQog_FHUHAFVRsO4otlwzn0bZspSAefOl", "PLLMA7Sh3JsORlZSt9eMT49ejfGYrY0IKG", "PLtYHnS0mhkb_WVLIVwCErFLnjtJrSozkt", "PLzauiyXIK7Rj1h23BPvDb3sQwmzHhRuyX", "PLNDw0dvPrjjcEIv7Q-LE5of7uUOmZ2tgD", "PLcfQmtiAG0X_byEjBwRXaGJ9WoJL_ntNr", "PLFbKRa_kS4i852ZBCW0XyrVEZzanMFY2a", "PL0zQrw6ZA60bl5Cq6cv83xp8E38oIzosA", "PLq-ZRVZ1W4FcimhT61WDkh71_3CDL1KBD", "PLhi9vMiphA8JFV-UHsneYH3i6mgp6ZGWR", "PLo5cIhJ0-8jnS_E2ZG0Je2Dt_jQuvgP_Y", "PLJ0Pbja2awaNscjVUAzmED4RwxpwbCPYd", "PLzOnHpG7pFWJoAgEMyCpi8btTYPvzwTU5", "PLI39zLOagDhxUAsY315e1ERavyUqZ6ovS", "PLSn1U7lJJ1UljgQSw3bfmYmfB1en3MbEF"]
    
    var playlistsSnippet = [(title: String, thumbUrl: NSURL)]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Youtube.getPlaylistsSinppet(playlists) { (playlistsSnippets) -> () in
            self.playlistsSnippet = playlistsSnippets
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.tableView.reloadData()
            })
        }
    }
    
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        MBProgressHUD.hideHUDForView(self.tabBarController?.view, animated: true)
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return playlistsSnippet.count
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("playlistCell", forIndexPath: indexPath)
        
        // Configure the cell...
        
        cell.textLabel?.text = playlistsSnippet[indexPath.row].title
        cell.imageView?.kf_setImageWithURL(playlistsSnippet[indexPath.row].thumbUrl, placeholderImage: UIImage(named: "blankStandard"))
        
        //from popup demo app
        let selectionView = UIView()
        selectionView.backgroundColor = Musical.color.colorWithAlphaComponent(0.45)
        cell.selectedBackgroundView = selectionView
        
        return cell
    }
    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        
        let vc = segue.destinationViewController as! DiscoverPlaylistTableViewController
        // Pass the selected object to the new view controller.
        vc.playlistId = playlists[tableView.indexPathForSelectedRow!.row]
        vc.playlistTitle = playlistsSnippet[tableView.indexPathForSelectedRow!.row].title
    }
    
    override func viewDidAppear(animated: Bool) {
        if playlistsSnippet.count == 0 {
            MBProgressHUD.showHUDAddedTo(tabBarController!.view, animated: true)
        }
    }
    
    //ios bug? row stays selected when swipping back
    override func viewWillAppear(animated: Bool) {
        
        if tableView.indexPathForSelectedRow != nil {
            tableView.deselectRowAtIndexPath(tableView.indexPathForSelectedRow!, animated: true)
        }
        
        //this is needed if no rsults due to no internet connection when viewdidloaded, try again on each view
        
        if playlistsSnippet.count == 0 {
            Youtube.getPlaylistsSinppet(playlists) { (playlistsSnippets) -> () in
                self.playlistsSnippet = playlistsSnippets
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.tableView.reloadData()
                })
            }
        }
    }
    
}
