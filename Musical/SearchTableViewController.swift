//
//  SearchTableViewController.swift
//  Musical
//
//  Created by Sebastian on 10/24/15.
//  Copyright © 2015 Sebastian. All rights reserved.
//

import UIKit
import Kingfisher

class SearchTableViewController: UITableViewController, UISearchResultsUpdating, UISearchControllerDelegate, UISearchBarDelegate {
    
    let suggestionsLang = "en"
    let maxResults = 25
    
    let searchController = UISearchController(searchResultsController: nil)
    
    //debug
    var recentQueries = ["the rewalest","fo fighter","asad"]
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
        
        
    }
    
    
    
    //MARK: UISearchResultsUpdating
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {

        if searchController.searchBar.text!.isEmpty
        {
            currentDisplayMode = .Recent
           
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
            
            cell.imageView?.kf_setImageWithURL(results[indexPath.row].thumbURL, placeholderImage: UIImage(named: "defaultCellThumb"))
            
            //channelBrandtitle can be nil, use channeltitle
            cell.detailTextLabel?.text = results[indexPath.row].duration  + " " + ((results[indexPath.row].isHD == true) ? "[HD]" : "") + " " + (results[indexPath.row].channelBrandTitle == nil ? results[indexPath.row].channelTitle : results[indexPath.row].channelBrandTitle!)
            
            
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
            cell.textLabel?.text = recentQueries[indexPath.row]
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
            }
            
            let popupContentController = storyboard?.instantiateViewControllerWithIdentifier("playerViewController") as! PlayerViewController
            popupContentController.videoTitle = results[indexPath.row].title
            popupContentController.channelTitle = results[indexPath.row].channelBrandTitle == nil ? results[indexPath.row].channelTitle : results[indexPath.row].channelBrandTitle!
            popupContentController.videoId = results[indexPath.row].id
            
            tabBarController?.presentPopupBarWithContentViewController(popupContentController, animated: true, completion: nil)
            
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            
        case .Recent:
            currentDisplayMode = .Result
            searchController.searchBar.text = recentQueries[indexPath.row]
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