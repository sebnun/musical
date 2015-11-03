//
//  YoutubeParser.swift
//  Musical
//
//  Created by Sebastian on 10/24/15.
//  Copyright © 2015 Sebastian. All rights reserved.
//

import Foundation

class Youtube {

    
    //youtube api provides title, thumbnails, if is live
    //and has file properties, can just look for the best itag based on the api? using https://en.wikipedia.org/wiki/YouTube#Quality_and_formats
    //so I need to get the itags url, and the lenght? or the lenght is handled by avplayer?
    // see http://coding-everyday.blogspot.com.uy/2013/03/how-to-grab-youtube-playback-video-files.html
    

    private static let apiKey = "AIzaSyBLTCguAqfQ1K4ejgMQwB0gNTgH4RHA5p8"
    
    
    //could use pagination using nextPageToken? KISS for now
    
    static func getSearchResults(query: String, completionClosure: (results: [YoutubeItem], videoIds: String) -> ()) {
        
        var results = [YoutubeItem]()

        let query = query.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!
        let urlString = "https://www.googleapis.com/youtube/v3/search?part=snippet&maxResults=50&q=\(query)&type=video&key=\(apiKey)"
        let url = NSURL(string: urlString)!
        
        
        NSURLSession.sharedSession().dataTaskWithURL(url) { (data, response, error) -> Void in
            
            if ( error != nil) {
                print("yt error \(error)")
            }
            
            let resultsDict = (try! NSJSONSerialization.JSONObjectWithData(data!, options: [])) as! Dictionary<NSObject, AnyObject>
            
            // Get all search result items ("items" array).
            let items: Array<Dictionary<NSObject, AnyObject>> = resultsDict["items"] as! Array<Dictionary<NSObject, AnyObject>>
            
            var videoIds = ""
            
            // Loop through all search results and keep just the necessary data.
            for i in  0..<items.count {
                
                let snippetDict = items[i]["snippet"] as! Dictionary<NSObject, AnyObject>
  
                let title =  snippetDict["title"] as! String
                
                
                let channelTitle = snippetDict["channelTitle"] as! String
                
                
                //has 3 thumsb, default seems to be the most appropriet to display in SERPs
                let thumbnail = ((snippetDict["thumbnails"] as! Dictionary<NSObject, AnyObject>)["default"] as! Dictionary<NSObject, AnyObject>)["url"] as! String
                
                let videoId = (items[i]["id"] as! Dictionary<NSObject, AnyObject>)["videoId"] as! String
                
                let live = (snippetDict["liveBroadcastContent"] as! String) == "none" ? false : true
            
                let item = YoutubeItem(title: title, channelTitle: channelTitle, id: videoId, thumbURL: NSURL(string: thumbnail), duration: nil, isLive: live )
                
                results.append(item)
                
                videoIds.appendContentsOf("\(videoId),")
            }
            

            completionClosure(results: results, videoIds: videoIds)
        
        }.resume()
        

    }
    
    
    static func getVideosDuration(videoIds: String, completionClosure: (durations: [String]) -> ()) {
        
        var durations = [String]()
        var videosIdsEncoded = videoIds.stringByReplacingOccurrencesOfString(",", withString: "%2C")
        videosIdsEncoded.removeAtIndex(videosIdsEncoded.endIndex.predecessor())
        videosIdsEncoded.removeAtIndex(videosIdsEncoded.endIndex.predecessor())
        videosIdsEncoded.removeAtIndex(videosIdsEncoded.endIndex.predecessor())
        
        let urlString = "https://www.googleapis.com/youtube/v3/videos?part=contentDetails&id=\(videosIdsEncoded)&key=\(apiKey)"
        let url = NSURL(string: urlString)!
        
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
                
                durations.append(parseDuration(duration))
            }
            
            completionClosure(durations: durations)

        }.resume()

    }
    
    static func parseDuration(duration: String) -> String {
        
        let regex = try! NSRegularExpression(pattern: "(\\d+)[DTHMS]", options: [])
        let matches = regex.matchesInString(duration, options: [], range: NSMakeRange(0, duration.characters.count))
    
        let dur = (duration as NSString)
        
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
            
        var sec = (duration as NSString).substringWithRange(matches[0].range) as String
        sec = String(sec.characters.dropLast())
            
        return "0:\(sec.characters.count == 2 ? sec : "0" + sec)"
        
    }
    
}

struct YoutubeItem {
    
    let title: String!
    let channelTitle: String!
    let id: String!
    let thumbURL: NSURL! //has 3 in search api, but default, smaller is enogh to display in tableview
    var duration: String!
    let isLive: Bool!
}





