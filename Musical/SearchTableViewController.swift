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
    
    var currentDisplayMode = displayMode.recent
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        suggestionsLang = getLocaleLang()
        
        //update country connection once every time the app is loaded?
        Musical.getConnectionCountryCode({ (countryCode) -> () in
            Musical.countryCode = countryCode
        })
        
        searchController.searchBar.delegate = self
        searchController.delegate = self
        searchController.searchResultsUpdater = self
        searchController.hidesNavigationBarDuringPresentation = false //setting this to true show cancel buttin wtf
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.autocapitalizationType = .none //disable capitalization
        searchController.searchBar.keyboardAppearance = .dark
        
        definesPresentationContext = true //to not appear black between tabs
        
        navigationItem.titleView = searchController.searchBar
        navigationItem.titleView?.tintColor = Musical.color //thisis needed beacuse the cursor in the searchabr disspaer sometiomes
        
        //to dismiss keyboars when scrollin
        tableView.keyboardDismissMode = .onDrag
        
        if let recent = UserDefaults.standard.object(forKey: "recentQueries") {
            recentQueries = recent as! [NSString]
        }

    }
    
    //MARK: UISearchResultsUpdating
    
    func updateSearchResults(for searchController: UISearchController) {

        if searchController.searchBar.text!.isEmpty
        {
            currentDisplayMode = .recent
            
            if let recent = UserDefaults.standard.object(forKey: "recentQueries") {
                recentQueries = recent as! [NSString]
            }
           
            tableView.reloadData()
            
        } else if currentDisplayMode == .result {
           
            results.removeAll()
            tableView.reloadData()
            
            Youtube.getSearchResults(searchController.searchBar.text!, isNewQuery: true, maxResults: maxResults, completionClosure: { (results) -> () in
                
                self.results = results
                self.tableView.reloadData()
                
            })
            
        } else if currentDisplayMode == .suggestion {
            
            Youtube.getSearchSuggestions(searchController.searchBar.text!, lang: suggestionsLang, completionHandler: { (suggestions) -> () in
                
                self.suggestions = suggestions
                
                DispatchQueue.main.async(execute: { () -> Void in
                    self.tableView.reloadData()
                })
            })
        }
    }
    
    //MARK: UISearchControllerDelegate
    
    //to disable cance button
    func didPresentSearchController(_ searchController: UISearchController) {
        searchController.searchBar.showsCancelButton = false
    }
    
    //MARK: UISearchBarDelegate
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        currentDisplayMode = .suggestion
    }
    
    //to trigger searchj from tap on keyboard search
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        currentDisplayMode = .result
        searchController.searchBar.text = searchController.searchBar.text
    
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        if currentDisplayMode == .result && results.count == 0 {
            
            let tableMessageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
            
            //it means it was loading ... before and now it has nor results from search
            if tableView.backgroundView != nil {
                
                MBProgressHUD.hide(for: self.tabBarController?.view, animated: true)
                tableMessageLabel.text = NSLocalizedString("No Results.", comment: "")
            } else {
                
                MBProgressHUD.showAdded(to: tabBarController?.view, animated: true)

            }
            
            tableMessageLabel.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)
            tableMessageLabel.textAlignment = .center
            tableView.backgroundView = tableMessageLabel
            tableView.separatorStyle = .none
            
            //full screen ads, this callsd prepareforintersatialads also?
            interstitialPresentationPolicy = .manual
            
            return 0
            
        } else {
            
            MBProgressHUD.hide(for: tabBarController?.view, animated: true)
            
            tableView.backgroundView = nil
            tableView.separatorStyle = .singleLine
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        switch currentDisplayMode {
        case .recent:
            return recentQueries.count
        case .result:
            return results.count
        case .suggestion:
            return suggestions.count
        }
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch currentDisplayMode {
            
        case .result:
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "searchCell", for: indexPath)
            
            cell.textLabel?.text = results[indexPath.row].title
            
            cell.imageView?.kf.setImage(with: results[indexPath.row].thumbURL, placeholder: UIImage(named: "blank"))
            
            //cell.imageView?.kf_setImageWithURL(results[indexPath.row].thumbURL, placeholderImage: UIImage(named: "blank"))
            cell.detailTextLabel?.text = results[indexPath.row].duration  + " " + (results[indexPath.row].channelBrandTitle ?? results[indexPath.row].channelTitle) //channelBrandtitle can be nil, use channeltitle
            
            
//            if results[indexPath.row].regionsAllowed != nil {
//                cell.detailTextLabel?.text?.appendContentsOf(" A: ")
//                
//                for region in results[indexPath.row].regionsAllowed! {
//                    cell.detailTextLabel?.text?.appendContentsOf("\(region) ")
//                }
//            }
//            
//            if results[indexPath.row].regionsBlocked != nil {
//                cell.detailTextLabel?.text?.appendContentsOf(" B: ")
//                
//                for region in results[indexPath.row].regionsBlocked! {
//                    cell.detailTextLabel?.text?.appendContentsOf("\(region) ")
//                }
//            }
            
            if results[indexPath.row].isHD == true {
                
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

            //check to load more serps
            if(indexPath.row == results.count - 5 && results.count >= maxResults) {
                
                Youtube.getSearchResults(searchController.searchBar.text!, isNewQuery: false, maxResults: maxResults, completionClosure: { (results) -> () in
                    
                    self.results.append(contentsOf: results)
                    self.tableView.reloadData()
                })
            }
            
            return cell
            
        case .recent:
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "recentCell", for: indexPath)
            cell.textLabel?.text = recentQueries[indexPath.row] as String
            return cell
            
        case .suggestion:
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "recentCell", for: indexPath)
            cell.textLabel?.text = suggestions[indexPath.row]
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch currentDisplayMode {
            
        case .result:
            //this is where  I know the wury was useful, onl;y store recent from here
            if !recentQueries.contains(searchController.searchBar.text! as NSString) {
                recentQueries.insert(searchController.searchBar.text! as NSString, at: 0)
                
                UserDefaults.standard.set(recentQueries, forKey: "recentQueries")
            }
            
            if Musical.noInternetWarning() {
                return
            }
            
            //keyboards stay open when view video
            searchController.searchBar.resignFirstResponder()
            //searchController.resignFirstResponder() //to show popubar when tap on resut
            
            Musical.presentPlayer(results[indexPath.row])
            
            tableView.deselectRow(at: indexPath, animated: true)
            
            requestInterstitialAdPresentation()
            
        case .recent:
            currentDisplayMode = .result
            searchController.searchBar.text = recentQueries[indexPath.row] as String
        case .suggestion:
            currentDisplayMode = .result
            searchController.searchBar.text = suggestions[indexPath.row]
        }
        
    }
    
    func getLocaleLang() -> String {
        
        //same lang codes in ios and google, ecept chinese
        var lang = Locale.preferredLanguages.first!
        
        if lang == "zh-Hans" {
            lang = "zh-CN"
        } else if lang == "zh-Hant" {
            lang = "zh-TW"
        }
        
        return lang
    }
}

enum displayMode {
    case recent
    case result
    case suggestion
}
