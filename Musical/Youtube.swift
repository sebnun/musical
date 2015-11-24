//
//  YoutubeParser.swift
//  Musical
//
//  Created by Sebastian on 10/24/15.
//  Copyright © 2015 Sebastian. All rights reserved.
//

import Foundation

class Youtube {

    //and has file properties, can just look for the best itag based on the api? using https://en.wikipedia.org/wiki/YouTube#Quality_and_formats
    //can not get file data with api
    
    //hq thumb and video streams from hcyoutubeparser
    //but some videos. like music video youtube.com/get_video_info gets error, content restricted, but music can played them, so use official tool
    
    //http://shreyaschand.com/blog/2013/01/03/google-autocomplete-api/
    static func getSearcSuggestions(query: String, lang: String, completionHandler: (suggestions: [String]) -> ()) {
        
        var suggestions = [String]()
        
        let query = query.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!
        let urlString = "http://suggestqueries.google.com/complete/search?q=\(query)&client=firefox&hl=\(lang)&ds=yt"
        let url = NSURL(string: urlString)!
        
        NSURLSession.sharedSession().dataTaskWithURL(url) { (data, response, error) -> Void in
            
            if ( error != nil) {
                print("yt error \(error)")
            }
            
            let json = JSON(data: data!)
            
            for (_, suggestion) in json[1] {
                suggestions.append(suggestion.stringValue)
            }
            
            completionHandler(suggestions: suggestions)
            
            }.resume()
        
        
    }


    private static let apiKey = "AIzaSyBLTCguAqfQ1K4ejgMQwB0gNTgH4RHA5p8"
    private static var nextPageToken = ""
    
    //need isNewQury cause they can tap search on keyboard to make new quey with same keywords after getting results updating
    static func getSearchResults(query: String, isNewQuery: Bool, maxResults: Int, completionClosure: (results: [YoutubeItem]) -> ()) {
        
        
        if isNewQuery {
            nextPageToken = ""
        }
        
        var results = [YoutubeItem]()
        
        //if is trying to get more results for the same quey but last results says it doesnt have more, just return no results
        if !isNewQuery && nextPageToken == "" {
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completionClosure(results: results)
            })
            
            return
        }

        let query = query.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!
        let urlString = "https://www.googleapis.com/youtube/v3/search?part=snippet&maxResults=\(maxResults)&q=\(query)&type=video&key=\(apiKey)\(nextPageToken == "" ? "" : "&pageToken=" + nextPageToken)"
        let url = NSURL(string: urlString)!
        
        //print("about to start  download seatch api")
        
        NSURLSession.sharedSession().dataTaskWithURL(url) { (data, response, error) -> Void in
            
            //this is executed on a bacjround thred by defautl
            
            if ( error != nil) {
                print("yt error \(error)")
            }
            
            let resultsDict = (try! NSJSONSerialization.JSONObjectWithData(data!, options: [])) as! Dictionary<NSObject, AnyObject>
            
            //to make pagination in ui, last pages dont have next page token
            if resultsDict["nextPageToken"] != nil {
                nextPageToken = resultsDict["nextPageToken"] as! String
            } else {
                nextPageToken = ""
            }
            
            // Get all search result items ("items" array).
            let items: Array<Dictionary<NSObject, AnyObject>> = resultsDict["items"] as! Array<Dictionary<NSObject, AnyObject>>
            
            //no results
            if items.count == 0 {
                nextPageToken = ""
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    completionClosure(results: results)
                })
                
                return
            }
            
            var videoIds = ""
            var channelIds = ""
            
            // Loop through all search results and keep just the necessary data.
            for i in  0..<items.count {
                
                let snippetDict = items[i]["snippet"] as! Dictionary<NSObject, AnyObject>
  
                let title =  snippetDict["title"] as! String
                let channelId =  snippetDict["channelId"] as! String
                let channelTitle = snippetDict["channelTitle"] as! String
                //has 3 thumsb, default seems to be the most appropriet to display in SERPs
                let thumbnail = ((snippetDict["thumbnails"] as! Dictionary<NSObject, AnyObject>)["default"] as! Dictionary<NSObject, AnyObject>)["url"] as! String
                let videoId = (items[i]["id"] as! Dictionary<NSObject, AnyObject>)["videoId"] as! String
                let live = (snippetDict["liveBroadcastContent"] as! String) == "none" ? false : true
            
                let item = YoutubeItem(title: title, channelTitle: channelTitle, id: videoId, thumbURL: NSURL(string: thumbnail), duration: nil, isLive: live, channelId: channelId, isHD: nil, channelBrandTitle: nil)
                
                results.append(item)
                
                videoIds.appendContentsOf("\(videoId),")
                channelIds.appendContentsOf("\(channelId),")
                
            }
            
            videoIds = videoIds.stringByPreparingForYTAPI()
            channelIds = channelIds.stringByPreparingForYTAPI()
            
            
            let dispatchGroup = dispatch_group_create()
            
            dispatch_group_enter(dispatchGroup)
            getVideosDurationDefinition(videoIds, completionClosure: { (durations, definitions) -> () in
                
                for (index, _) in results.enumerate() {
                    results[index].duration = durations[index]
                    results[index].isHD = definitions[index]
                }
                
                dispatch_group_leave(dispatchGroup)
            })
            
//            dispatch_group_enter(dispatchGroup)
//            getVideosChannelBrandTitle(channelIds, completionClosure: { (brandTitles) -> () in
//                for (index, _) in results.enumerate() {
//                    results[index].channelBrandTitle = brandTitles[index]
//                }
//                
//                dispatch_group_leave(dispatchGroup)
//            })
            

            dispatch_group_notify(dispatchGroup, dispatch_get_main_queue(), { () -> Void in
                completionClosure(results: results)
            })
            
        
        }.resume()
        

    }
    

    
    private static func getVideosDurationDefinition(videoIds: String, completionClosure: (durations: [String], definitions: [Bool]) -> ()) {
        
        var durations = [String]()
        var definitions = [Bool]()
        
        let urlString = "https://www.googleapis.com/youtube/v3/videos?part=contentDetails&id=\(videoIds)&key=\(apiKey)"
        let url = NSURL(string: urlString)!
        
        //print("about to start  download video api")
        
        NSURLSession.sharedSession().dataTaskWithURL(url) { (data, response, error) -> Void in
            
            if ( error != nil) {
                print("yt error \(error)")
            }
            
            let resultsDict = (try! NSJSONSerialization.JSONObjectWithData(data!, options: [])) as! Dictionary<NSObject, AnyObject>
            
            // Get all search result items ("items" array).
            let items: Array<Dictionary<NSObject, AnyObject>> = resultsDict["items"] as! Array<Dictionary<NSObject, AnyObject>>
            
            // Loop through all search results and keep just the necessary data.
            for i in  0..<items.count {
                
                let snippetDict = items[i]["contentDetails"] as! Dictionary<NSObject, AnyObject>
                
                let duration =  snippetDict["duration"] as! String
                let isHD = snippetDict["definition"] as! String == "sd" ? false : true
                
                definitions.append(isHD)
                durations.append(duration.stringFromISO8601Duration())
            }
            
            completionClosure(durations: durations, definitions: definitions)

        }.resume()

    }
    
    private static func getVideosChannelBrandTitle(channelIds: String, completionClosure: (brandTitles: [String?]) -> ()) {
        
        var brandTitles = [String?]()
        
        let urlString = "https://www.googleapis.com/youtube/v3/channels?part=brandingSettings&id=\(channelIds)&key=\(apiKey)"
        let url = NSURL(string: urlString)!
        
        //print("about to start  download channel api")
        
        NSURLSession.sharedSession().dataTaskWithURL(url) { (data, response, error) -> Void in
            
            if ( error != nil) {
                print("yt error \(error)")
            }
            
            let resultsDict = (try! NSJSONSerialization.JSONObjectWithData(data!, options: [])) as! Dictionary<NSObject, AnyObject>
            
            // Get all search result items ("items" array).
            let items: Array<Dictionary<NSObject, AnyObject>> = resultsDict["items"] as! Array<Dictionary<NSObject, AnyObject>>
            
            // Loop through all results and keep just the necessary data.
            for i in  0..<items.count {
                
                let brandSettingsDict = items[i]["brandingSettings"] as! Dictionary<NSObject, AnyObject>
                let channelDict = brandSettingsDict["channel"] as! Dictionary<NSObject, AnyObject>
                
                //can be nil
                let brandTitle = channelDict["title"] as? String
                
                brandTitles.append(brandTitle)
                
            }
            
            completionClosure(brandTitles: brandTitles)
            
        }.resume()
        
    }
    
}

struct YoutubeItem {
    
    let title: String! //from search api
    let channelTitle: String! //from search api, can be empty, not the real one dispplayed on youtube ui
    let id: String! //from search api
    let thumbURL: NSURL! //from searcvh api, has 3 but default is enogh to display in tableview
    var duration: String! //video,contenDetails api
    let isLive: Bool! //from search api
    let channelId: String! //from search api
    var isHD: Bool! //from video,contenDetails api
    var channelBrandTitle: String? // from channel,brandingSettings.channel.title api
}

extension String {
    
    func stringFromISO8601Duration() -> String {
        
        let regex = try! NSRegularExpression(pattern: "(\\d+)[DTHMS]", options: [])
        let matches = regex.matchesInString(self, options: [], range: NSMakeRange(0, self.characters.count))
        
        let dur = (self as NSString)
        
        if matches.count == 4 {
            
            var days = dur.substringWithRange(matches[0].range) as String
            days = String(days.characters.dropLast())
            var hours = dur.substringWithRange(matches[1].range) as String
            hours = String(hours.characters.dropLast())
            var min = dur.substringWithRange(matches[2].range) as String
            min = String(min.characters.dropLast())
            var sec = dur.substringWithRange(matches[3].range) as String
            sec = String(sec.characters.dropLast())
            
            return "\(days):\(hours.characters.count == 2 ? hours : "0" + hours):\(min.characters.count == 2 ? min : "0" + min):\(sec.characters.count == 2 ? sec : "0" + sec)"
            
        } else if matches.count == 3 {
            
            
            var hours = dur.substringWithRange(matches[0].range) as String
            hours = String(hours.characters.dropLast())
            var min = dur.substringWithRange(matches[1].range) as String
            min = String(min.characters.dropLast())
            var sec = dur.substringWithRange(matches[2].range) as String
            sec = String(sec.characters.dropLast())
            
            return "\(hours):\(min.characters.count == 2 ? min : "0" + min):\(sec.characters.count == 2 ? sec : "0" + sec)"
            
        } else if matches.count == 2 {
            
            var min = dur.substringWithRange(matches[0].range) as String
            min = String(min.characters.dropLast())
            var sec = dur.substringWithRange(matches[1].range) as String
            sec = String(sec.characters.dropLast())
            
            return "\(min):\(sec.characters.count == 2 ? sec : "0" + sec)"
            
        }
        
        var sec = dur.substringWithRange(matches[0].range) as String
        sec = String(sec.characters.dropLast())
        
        return "0:\(sec.characters.count == 2 ? sec : "0" + sec)"
        
    }
    
    func stringByPreparingForYTAPI() -> String {
        
        var stringEncoded = self.stringByReplacingOccurrencesOfString(",", withString: "%2C")
        stringEncoded.removeAtIndex(stringEncoded.endIndex.predecessor())
        stringEncoded.removeAtIndex(stringEncoded.endIndex.predecessor())
        stringEncoded.removeAtIndex(stringEncoded.endIndex.predecessor())
        
        return stringEncoded
    }

}



