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
            
            DispatchQueue.main.async(execute: { () -> Void in
                self.tableView.reloadData()
            })
        }
        
        title = playlistTitle
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if items.count == 0 {
            MBProgressHUD.showAdded(to: tabBarController!.view, animated: true)
        }
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        MBProgressHUD.hide(for: tabBarController!.view, animated: true)
        
        //full screen ads, this callsd prepareforintersatialads also?
        interstitialPresentationPolicy = .manual
        
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "playlistItemCell", for: indexPath)
        
        cell.textLabel?.text = items[indexPath.row].title
        cell.imageView?.kf.setImage(with: items[indexPath.row].thumbURL, placeholder: UIImage(named: "blank"))
//        cell.imageView?.kf_setImageWithURL(items[indexPath.row].thumbURL, placeholderImage: UIImage(named: "blank"))
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
            label.textColor = UIColor.white
            label.font  = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption1)
            label.backgroundColor = UIColor.black
            label.sizeToFit()
            
            cell.imageView?.addSubview(label)
        } else {      //subviews stay after resuse, remove them
            for view in cell.imageView!.subviews {
                view.removeFromSuperview()
            }
        }
        
        //from popup demo app
        let selectionView = UIView()
        selectionView.backgroundColor = Musical.color.withAlphaComponent(0.45)
        cell.selectedBackgroundView = selectionView
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if Musical.noInternetWarning() {
            return
        }
        
        Musical.presentPlayer(items[indexPath.row])
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        requestInterstitialAdPresentation()
    }
    
    
    
}
