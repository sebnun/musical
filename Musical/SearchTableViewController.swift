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
    
    let searchController = UISearchController(searchResultsController: nil)
    
    //debug
    var recentQueries = ["dasdsa","adsads","asdsad"]
    var results = [YoutubeItem]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        searchController.searchBar.delegate = self
        searchController.delegate = self
        searchController.searchResultsUpdater = self
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.autocapitalizationType = .None //disable capitalization
        
        definesPresentationContext = true //to not appear black between tabs
        navigationItem.titleView = searchController.searchBar
        
        //to dismiss keyboars when scrollin
        //gives cursos bug
        //tableView.keyboardDismissMode = .OnDrag
    }
    

    
    //MARK: UISearchResultsUpdating
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        
        searchController.searchBar.becomeFirstResponder()
        
        if (searchController.searchBar.text?.isEmpty == false)
        {
            Youtube.getSearchResults(searchController.searchBar.text!, completionClosure: { (results, videoIds) -> () in
                
                self.results = results
                
                if results.count != 0 {
                    
                    Youtube.getVideosDuration(videoIds, completionClosure: { (durations) -> () in
                        
                        for (index, _) in self.results.enumerate() {
                            
                            self.results[index].duration = durations[index]
                        }
                        
                        NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                            self.tableView.reloadData()
                        })
                    })
                    
                } else {
                    
                    NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                        self.tableView.reloadData()
                    })
                }
                
                
            })
            
        }
    }
    
    //MARK: UISearchControllerDelegate
    
    //to disable cance button
    func didPresentSearchController(searchController: UISearchController) {
        searchController.searchBar.showsCancelButton = false
    }
    
    //MARK: UISearchBarDelegate
    //to go back to recentqueries when x is tapped
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            searchController.active = false
            searchBar.resignFirstResponder()
            tableView.reloadData()
        }
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if (searchController.active) {
            return results.count
        }
        else {
            return recentQueries.count
        }
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        
        if (searchController.active) {
            
            let cell = tableView.dequeueReusableCellWithIdentifier("searchCell", forIndexPath: indexPath)
            
            cell.textLabel?.text = results[indexPath.row].title
            
            cell.imageView?.kf_setImageWithURL(results[indexPath.row].thumbURL, placeholderImage: UIImage(named: "defaultCellThumb"))
            
            //sometimes channeltitle is empty, musi uses other api call for the channel name that always has value
            //kiss for now
            cell.detailTextLabel?.text = "\(results[indexPath.row].duration) \(results[indexPath.row].channelTitle == "" ? "" : "- HD -" + results[indexPath.row].channelTitle)"
            
//            let durationLabel = UILabel(frame: CGRectMake(0, 0, 50, 10))
//            durationLabel.font = UIFont(name: "Helvetica", size: 9)
//            durationLabel.text = results[indexPath.row].duration
//            cell.accessoryView = durationLabel
            
            //check to load more serps
            if(indexPath.row == results.count - 1 && results.count >= 50) {
                
                Youtube.getSearchResults(searchController.searchBar.text!, completionClosure: { (results, videoIds) -> () in
                    
                    var localResults = results
                    
                    if localResults.count > 0 { //can this return 0?
                        
                        Youtube.getVideosDuration(videoIds, completionClosure: { (durations) -> () in
                            
                            for (index, _) in localResults.enumerate() {
                                
                                localResults[index].duration = durations[index]
                            }
                            
                            self.results.appendContentsOf(localResults)
                            
                            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                                self.tableView.reloadData()
                            })
                        })
                        
                    }
                    
                    
                })
                
            }
            
            return cell
            
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("recentCell", forIndexPath: indexPath)
            cell.textLabel?.text = recentQueries[indexPath.row]
            return cell
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if (searchController.active) {
            //this is where it should store the seachr term, cause it means the search query was useful
            if (!recentQueries.contains(searchController.searchBar.text!)) {
                recentQueries.insert(searchController.searchBar.text!, atIndex: 0)
            }
        } else {
            
            searchController.active = true
            searchController.searchBar.text = recentQueries[indexPath.row]
        }
    }
    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        
        
    }
    
    
}
