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
        tableView.keyboardDismissMode = .OnDrag
    }
    

    
    //MARK: UISearchResultsUpdating
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        
        searchController.searchBar.becomeFirstResponder()
        
        if (searchController.searchBar.text?.isEmpty == false)
        {
            Youtube.getSearchResults(searchController.searchBar.text!, isNewQuery: true, completionClosure: { (results) -> () in
                
                //in main queue here?
                
                self.results = results
                
                self.tableView.reloadData()
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
            
            //channelBrandtitle can be nil, use channeltitle
            cell.detailTextLabel?.text = results[indexPath.row].duration  + " " + ((results[indexPath.row].isHD == true) ? "[HD]" : "") + " " + (results[indexPath.row].channelBrandTitle == nil ? results[indexPath.row].channelTitle : results[indexPath.row].channelBrandTitle!)

            
            //check to load more serps
            if(indexPath.row == results.count - 1 && results.count >= 50) {
                
                Youtube.getSearchResults(searchController.searchBar.text!, isNewQuery: false, completionClosure: { (results) -> () in
                    
                    self.results.appendContentsOf(results)
                    self.tableView.reloadData()
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
