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
    
    var suggestionsLang: String!
    let maxResults = 25
    
    let searchController = UISearchController(searchResultsController: nil)
    
    var recentQueries = [NSString]()
    var results = [YoutubeItemData]()
    var suggestions = [String]()
    
    var currentDisplayMode = displayMode.Recent
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        suggestionsLang = getLocaleLang()
        
        searchController.searchBar.delegate = self
        searchController.delegate = self
        searchController.searchResultsUpdater = self
        searchController.hidesNavigationBarDuringPresentation = false //setting this to true show cancel buttin wtf
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.autocapitalizationType = .None //disable capitalization
        searchController.searchBar.keyboardAppearance = .Dark
        
        definesPresentationContext = true //to not appear black between tabs
        
        navigationItem.titleView = searchController.searchBar
        navigationItem.titleView?.tintColor = Musical.color //thisis needed beacuse the cursor in the searchabr disspaer sometiomes
        
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
            
            Youtube.getSearchResults(searchController.searchBar.text!, isNewQuery: true, maxResults: maxResults, completionClosure: { (results) -> () in
                
                self.results = results
                self.tableView.reloadData()
                
            })
            
        } else if currentDisplayMode == .Suggestion {
            
            Youtube.getSearchSuggestions(searchController.searchBar.text!, lang: suggestionsLang, completionHandler: { (suggestions) -> () in
                
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
                
                MBProgressHUD.hideHUDForView(self.tabBarController?.view, animated: true)
                tableMessageLabel.text = NSLocalizedString("No Results.", comment: "")
            } else {
                
                MBProgressHUD.showHUDAddedTo(self.tabBarController?.view, animated: true)

            }
            
            tableMessageLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
            tableMessageLabel.textAlignment = .Center
            tableView.backgroundView = tableMessageLabel
            tableView.separatorStyle = .None
            
            //full screen ads, this callsd prepareforintersatialads also?
            interstitialPresentationPolicy = .Manual
            
            return 0
            
        } else {
            
            MBProgressHUD.hideHUDForView(self.tabBarController?.view, animated: true)
            
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
            
            //to get the size of the imaeview
            //cell.imageView?.sizeToFit()

            
            if results[indexPath.row].isHD == true {
                
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
            cell.detailTextLabel?.text = results[indexPath.row].duration  + " " + (results[indexPath.row].channelBrandTitle ?? results[indexPath.row].channelTitle) + "\(results[indexPath.row].isLive)"
            
            
            //from popup demo app
            //TODO replace with app tint
            let selectionView = UIView()
            selectionView.backgroundColor = Musical.color.colorWithAlphaComponent(0.45)
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
            
            if Musical.noInternetWarning() {
                return
            }
            
            if Musical.popupContentController == nil {
                Musical.popupContentController = storyboard?.instantiateViewControllerWithIdentifier("playerViewController") as! PlayerViewController
                
                Musical.popupContentController.videoTitle = results[indexPath.row].title
                Musical.popupContentController.videoId = results[indexPath.row].id
                Musical.popupContentController.videoChannelTitle = results[indexPath.row].channelBrandTitle ?? results[indexPath.row].channelTitle
                
                tabBarController?.presentPopupBarWithContentViewController(Musical.popupContentController, openPopup: true, animated: true, completion: nil)
            } else {
            
                Musical.popupContentController.videoTitle = results[indexPath.row].title
                Musical.popupContentController.videoId = results[indexPath.row].id
                Musical.popupContentController.videoChannelTitle = results[indexPath.row].channelBrandTitle ?? results[indexPath.row].channelTitle
                
                Musical.popupContentController.setupForNewVideo()
                tabBarController?.openPopupAnimated(true, completion: nil)
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
    
    func getLocaleLang() -> String {
        
        //same lang codes in ios and google, ecept chinese
        var lang = NSLocale.preferredLanguages().first!
        
        if lang == "zh-Hans" {
            lang = "zh-CN"
        } else if lang == "zh-Hant" {
            lang = "zh-TW"
        }
        
        //print(lang)
        
        return lang
    }

    
    
}

enum displayMode {
    case Recent
    case Result
    case Suggestion
}