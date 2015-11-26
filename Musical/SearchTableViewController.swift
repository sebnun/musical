//
//  SearchTableViewController.swift
//  Musical
//
//  Created by Sebastian on 10/24/15.
//  Copyright © 2015 Sebastian. All rights reserved.
//

import UIKit
import Kingfisher
import iAd

class SearchTableViewController: UITableViewController, UISearchResultsUpdating, UISearchControllerDelegate, UISearchBarDelegate {
    
    let suggestionsLang = "en"
    let maxResults = 25
    
    let searchController = UISearchController(searchResultsController: nil)
    
    var recentQueries = [NSString]()
    var results = [YoutubeItem]()
    var suggestions = [String]()
    
    var currentDisplayMode = displayMode.Recent
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchController.searchBar.delegate = self
        searchController.delegate = self
        searchController.searchResultsUpdater = self
        searchController.hidesNavigationBarDuringPresentation = false //setting this to true show cancel buttin wtf
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.autocapitalizationType = .None //disable capitalization
        
        definesPresentationContext = true //to not appear black between tabs
        
        navigationItem.titleView = searchController.searchBar
        navigationItem.titleView?.tintColor = UIColor.blueColor() //thisis needed beacuse the cursor in the searchabr disspaer sometiomes
        
        //to dismiss keyboars when scrollin
        tableView.keyboardDismissMode = .OnDrag
        
        if let recent = NSUserDefaults.standardUserDefaults().objectForKey("recentQueries") {
            recentQueries = recent as! [NSString]
        }
    }
    
    
    
    //MARK: UISearchResultsUpdating
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {

        if searchController.searchBar.text!.isEmpty
        {
            currentDisplayMode = .Recent
            
            if let recent = NSUserDefaults.standardUserDefaults().objectForKey("recentQueries") {
                recentQueries = recent as! [NSString]
            }
           
            tableView.reloadData()
            
        } else if currentDisplayMode == .Result {
            
            
            results.removeAll()
            tableView.reloadData()
            
            //print("start searching")
            Youtube.getSearchResults(searchController.searchBar.text!, isNewQuery: true, maxResults: maxResults, completionClosure: { (results) -> () in
            
                //print("done searching")
                
                self.results = results
                
                //dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.tableView.reloadData()
                //})
                
            })
            
        } else if currentDisplayMode == .Suggestion {
            
            Youtube.getSearcSuggestions(searchController.searchBar.text!, lang: suggestionsLang, completionHandler: { (suggestions) -> () in
                
                self.suggestions = suggestions
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.tableView.reloadData()
                })
            })
        }
    }
    
    //MARK: UISearchControllerDelegate
    
    //to disable cance button
    func didPresentSearchController(searchController: UISearchController) {
        searchController.searchBar.showsCancelButton = false
    }
    
    //MARK: UISearchBarDelegate
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        currentDisplayMode = .Suggestion
    }
    
    //to trigger searchj from tap on keyboard search
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        currentDisplayMode = .Result
        searchController.searchBar.text = searchController.searchBar.text
    
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        if currentDisplayMode == .Result && results.count == 0 {
            
            let tableMessageLabel = UILabel(frame: CGRectMake(0, 0, tableView.bounds.size.width, tableView.bounds.size.height))
            
            //it means it was loading ... before and now it has nor results from search
            if tableView.backgroundView != nil {
                tableMessageLabel.text = "No Results."
            } else {
                tableMessageLabel.text = "Loading ..."
            }
            
            tableMessageLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
            tableMessageLabel.textAlignment = .Center
            tableView.backgroundView = tableMessageLabel
            tableView.separatorStyle = .None
            
            //full screen ads, this callsd prepareforintersatialads also?
            interstitialPresentationPolicy = .Manual
            
            return 0
            
        } else {
            
            tableView.backgroundView = nil
            tableView.separatorStyle = .SingleLine
            return 1
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        switch currentDisplayMode {
        case .Recent:
            return recentQueries.count
        case .Result:
            return results.count
        case .Suggestion:
            return suggestions.count
        }
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        switch currentDisplayMode {
            
        case .Result:
            
            let cell = tableView.dequeueReusableCellWithIdentifier("searchCell", forIndexPath: indexPath)
            
            cell.textLabel?.text = results[indexPath.row].title
            
            cell.imageView?.kf_setImageWithURL(results[indexPath.row].thumbURL, placeholderImage: UIImage(named: "blank"))
            
//            if results[indexPath.row].isHD == true {
//                
//                let label = UILabel()
//                label.text = "HD"
//                label.textColor = UIColor.whiteColor()
//                label.font  = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption1)
//                label.backgroundColor = UIColor.blackColor()
//                label.sizeToFit()
//                
//                //this doesnt work? .. just make it waorl in next version
//                //TOO SLOW
////                let effect = UIBlurEffect(style: .Dark)
////                let blurView = UIVisualEffectView(effect: effect)
////                blurView.frame = label.frame
////                blurView.addSubview(label)
//                
//                //i dont know how to put it on the bottom right of the imageview, it's better to implement the whole thiung as a custom uitableviewcell, leave as is
//                
//                cell.imageView?.addSubview(label)
//            } else if cell.imageView?.subviews.count > 0 { //because label stay while scrolling up? reusable stuff?
//                
//                for view in cell.imageView!.subviews {
//                    view.removeFromSuperview()
//                }
//            }
            
            //channelBrandtitle can be nil, use channeltitle
            cell.detailTextLabel?.text = results[indexPath.row].duration  /*+ " " + (results[indexPath.row].channelBrandTitle == nil ? results[indexPath.row].channelTitle : results[indexPath.row].channelBrandTitle!)*/
            
            
            //from popup demo app
            //TODO replace with app tint
            let selectionView = UIView()
            selectionView.backgroundColor = UIColor.blueColor().colorWithAlphaComponent(0.45)
            cell.selectedBackgroundView = selectionView

            //check to load more serps
            if(indexPath.row == results.count - 5 && results.count >= maxResults) {
                
                Youtube.getSearchResults(searchController.searchBar.text!, isNewQuery: false, maxResults: maxResults, completionClosure: { (results) -> () in
                    
                    self.results.appendContentsOf(results)
                    self.tableView.reloadData()
                })
            }
            
            return cell
            
        case .Recent:
            
            let cell = tableView.dequeueReusableCellWithIdentifier("recentCell", forIndexPath: indexPath)
            cell.textLabel?.text = recentQueries[indexPath.row] as String
            return cell
            
        case .Suggestion:
            
            let cell = tableView.dequeueReusableCellWithIdentifier("recentCell", forIndexPath: indexPath)
            cell.textLabel?.text = suggestions[indexPath.row]
            return cell
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        
        switch currentDisplayMode {
            
        case .Result:
            //this is where  I know the wury was useful, onl;y store recent from here
            if !recentQueries.contains(searchController.searchBar.text!) {
                recentQueries.insert(searchController.searchBar.text!, atIndex: 0)
                
                NSUserDefaults.standardUserDefaults().setObject(recentQueries, forKey: "recentQueries")
            }
            
            if popupContentController == nil {
                popupContentController = storyboard?.instantiateViewControllerWithIdentifier("playerViewController") as! PlayerViewController
                
                popupContentController.videoTitle = results[indexPath.row].title
                popupContentController.videoId = results[indexPath.row].id
                
                tabBarController?.presentPopupBarWithContentViewController(popupContentController, animated: true, completion: nil)
            } else {
            
                popupContentController.videoTitle = results[indexPath.row].title
                popupContentController.videoId = results[indexPath.row].id
                
                popupContentController.setupForNewVideo()
            
            }
            
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            
            searchController.resignFirstResponder() //to show popubar when tap on resut
            
            requestInterstitialAdPresentation()
            
        case .Recent:
            currentDisplayMode = .Result
            searchController.searchBar.text = recentQueries[indexPath.row] as String
        case .Suggestion:
            currentDisplayMode = .Result
            searchController.searchBar.text = suggestions[indexPath.row]
        }
        
    }
    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        
        
    }
    
    
}

enum displayMode {
    case Recent
    case Result
    case Suggestion
}