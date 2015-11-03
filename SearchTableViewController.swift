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
        
        definesPresentationContext = true
        navigationItem.titleView = searchController.searchBar

        
    }
    

    
    //MARK: UISearchResultsUpdating
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        
        searchController.searchBar.becomeFirstResponder()
        
        if (searchController.searchBar.text?.isEmpty == false)
        {
            
            Youtube.getSearchResults(searchController.searchBar.text!, completionClosure: { (results, videoIds) -> () in
                
                self.results = results
                
                Youtube.getVideosDuration(videoIds, completionClosure: { (durations) -> () in
                    
                    for (index, _) in self.results.enumerate() {
                        
                        self.results[index].duration = durations[index]
                        
                        //print(self.results[index].duration)
                    }
                    
                    NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                        self.tableView.reloadData()
                    })
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
            cell.imageView?.image = UIImage(named: "defaultCellThumb")  //set placeholder image first.
            
            cell.imageView?.downloadImageFrom(link: results[indexPath.row].thumbURL, contentMode: .ScaleAspectFit)

            cell.detailTextLabel?.text = "\(results[indexPath.row].duration) - \(results[indexPath.row].channelTitle)"
            
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

extension UIImageView {
    func downloadImageFrom(link link:NSURL, contentMode: UIViewContentMode) {
        NSURLSession.sharedSession().dataTaskWithURL( link, completionHandler: {
            (data, response, error) -> Void in
            dispatch_async(dispatch_get_main_queue()) {
                self.contentMode =  contentMode
                if let data = data { self.image = UIImage(data: data) }
            }
        }).resume()
    }
}
