//
//  SearchTableViewController.swift
//  Musical
//
//  Created by Sebastian on 10/24/15.
//  Copyright © 2015 Sebastian. All rights reserved.
//

import UIKit

class SearchTableViewController: UITableViewController, UISearchResultsUpdating, UISearchControllerDelegate, UISearchBarDelegate {
    
    let searchController = UISearchController(searchResultsController: nil)
    
    //debug
    var recentQueries = ["dasdsa","adsads","asdsad"]
    var results = [YoutubeSearchItem]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        searchController.searchBar.delegate = self
        searchController.delegate = self
        searchController.searchResultsUpdater = self
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.dimsBackgroundDuringPresentation = false
        searchController.definesPresentationContext = true
        
        self.navigationItem.titleView = searchController.searchBar
        
        
    }
    
    //MARK: UISearchResultsUpdating
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        
        if (searchController.searchBar.text?.isEmpty == false)
        {
            Youtube.getSearchResults(searchController.searchBar.text!, completionClosure: { (results) -> () in
                
                self.results = results
                
                NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
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
    //to go back to recentqueries when x is tapped
    //but aslo c
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
//        if searchText.isEmpty {
//            searchController.active = false
//            tableView.reloadData()
//        }
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
        
        var cell = UITableViewCell()
        
        if (searchController.active) {
            cell = tableView.dequeueReusableCellWithIdentifier("searchCell", forIndexPath: indexPath)
            cell.textLabel?.text = results[indexPath.row].title
        } else {
            cell = tableView.dequeueReusableCellWithIdentifier("recentCell", forIndexPath: indexPath)
            cell.textLabel?.text = recentQueries[indexPath.row]
        }

        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if (searchController.active) {
            //this is where it should store the seachr term, cause it means the search query was useful
            recentQueries.append(searchController.searchBar.text!)
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
