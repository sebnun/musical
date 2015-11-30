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


    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        //full screen ads, this callsd prepareforintersatialads also?
        interstitialPresentationPolicy = .Manual
        
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("playlistItemCell", forIndexPath: indexPath)

        // Configure the cell...
        cell.textLabel?.text = items[indexPath.row].title
        
        cell.imageView?.kf_setImageWithURL(items[indexPath.row].thumbURL, placeholderImage: UIImage(named: "blank"))
        
        //to get the size of the imaeview
        //cell.imageView?.sizeToFit()
        
        
        if items[indexPath.row].isHD == true {
            
            let label = UILabel()
            label.text = "HD"
            label.textColor = UIColor.whiteColor()
            label.font  = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption1)
            label.backgroundColor = UIColor.blackColor()
            label.sizeToFit()
            
            //this doesnt work? .. just make it waorl in next version
            //TOO SLOW
            //                let effect = UIBlurEffect(style: .ExtraLight)
            //                let blurView = UIVisualEffectView(effect: effect)
            //                blurView.clipsToBounds = true
            //                blurView.frame = label.bounds
            //                blurView.contentView.addSubview(label)
            
            //i dont know how to put it on the bottom right of the imageview, it's better to implement the whole thiung as a custom uitableviewcell, leave as is
            
            cell.imageView?.addSubview(label)
        } else {      //subviews stay after resuse, remove them
            for view in cell.imageView!.subviews {
                view.removeFromSuperview()
            }
        }
        
        
        
        
        //            let label = UILabel()
        //            label.text = results[indexPath.row].duration
        //            label.textColor = UIColor.whiteColor()
        //            label.font  = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption1)
        //            label.backgroundColor = UIColor.blackColor()
        //            label.sizeToFit()
        //
        //            print(cell.imageView!.bounds.height)
        //
        //            label.frame = CGRectMake(cell.imageView!.bounds.height - label.frame.height, cell.imageView!.bounds.width - label.frame.width, label.frame.width, label.frame.height)
        //
        //            cell.imageView!.addSubview(label)
        
        //channelBrandtitle can be nil, use channeltitle
        cell.detailTextLabel?.text = items[indexPath.row].duration  + " " + items[indexPath.row].channelTitle
        
        
        //from popup demo app
        //TODO replace with app tint
        let selectionView = UIView()
        selectionView.backgroundColor = Musical.color.colorWithAlphaComponent(0.45)
        cell.selectedBackgroundView = selectionView
        

        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        
        
            if Musical.popupContentController == nil {
                Musical.popupContentController = storyboard?.instantiateViewControllerWithIdentifier("playerViewController") as! PlayerViewController
                
                Musical.popupContentController.videoTitle = items[indexPath.row].title
                Musical.popupContentController.videoId = items[indexPath.row].id
                Musical.popupContentController.videoChannelTitle = items[indexPath.row].channelTitle
                
                tabBarController?.presentPopupBarWithContentViewController(Musical.popupContentController, openPopup: true, animated: true, completion: nil)
            } else {
                
                Musical.popupContentController.videoTitle = items[indexPath.row].title
                Musical.popupContentController.videoId = items[indexPath.row].id
                Musical.popupContentController.videoChannelTitle = items[indexPath.row].channelTitle
                
                Musical.popupContentController.setupForNewVideo()
                tabBarController?.openPopupAnimated(true, completion: nil)
            }
            
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            
            requestInterstitialAdPresentation()
        
        
    }



}
