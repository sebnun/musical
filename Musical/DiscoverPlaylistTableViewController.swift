//
//  DiscoverPlaylistTableViewController.swift
//  Musical
//
//  Created by Sebastian on 11/28/15.
//  Copyright © 2015 Sebastian. All rights reserved.
//

import UIKit

class DiscoverPlaylistTableViewController: UITableViewController {
    
    var playlistTitle: String!
    var playlistId: String!
    
    var items = [YoutubeItemData]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Youtube.getPlaylistItems(playlistId) { (items) -> () in
            self.items = items
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.tableView.reloadData()
            })
        }
        
        title = playlistTitle
    }
    
    override func viewDidAppear(animated: Bool) {
        if items.count == 0 {
            MBProgressHUD.showHUDAddedTo(tabBarController!.view, animated: true)
        }
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        MBProgressHUD.hideHUDForView(tabBarController!.view, animated: true)
        
        //full screen ads, this callsd prepareforintersatialads also?
        interstitialPresentationPolicy = .Manual
        
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("playlistItemCell", forIndexPath: indexPath)
        
        cell.textLabel?.text = items[indexPath.row].title
        cell.imageView?.kf_setImageWithURL(items[indexPath.row].thumbURL, placeholderImage: UIImage(named: "blank"))
        cell.detailTextLabel?.text = items[indexPath.row].duration  + " " + items[indexPath.row].channelTitle
        
//        if items[indexPath.row].regionsAllowed != nil {
//            cell.detailTextLabel?.text?.appendContentsOf(" A: ")
//            
//            for region in items[indexPath.row].regionsAllowed! {
//                cell.detailTextLabel?.text?.appendContentsOf("\(region) ")
//            }
//        }
//        
//        if items[indexPath.row].regionsBlocked != nil {
//            cell.detailTextLabel?.text?.appendContentsOf(" B: ")
//            
//            for region in items[indexPath.row].regionsBlocked! {
//                cell.detailTextLabel?.text?.appendContentsOf("\(region) ")
//            }
//        }
        
        if items[indexPath.row].isHD == true {
            
            let label = UILabel()
            label.text = "HD"
            label.textColor = UIColor.whiteColor()
            label.font  = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption1)
            label.backgroundColor = UIColor.blackColor()
            label.sizeToFit()
            
            cell.imageView?.addSubview(label)
        } else {      //subviews stay after resuse, remove them
            for view in cell.imageView!.subviews {
                view.removeFromSuperview()
            }
        }
        
        //from popup demo app
        let selectionView = UIView()
        selectionView.backgroundColor = Musical.color.colorWithAlphaComponent(0.45)
        cell.selectedBackgroundView = selectionView
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if Musical.noInternetWarning() {
            return
        }
        
        Musical.presentPlayer(items[indexPath.row])
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        requestInterstitialAdPresentation()
    }
    
    
    
}
