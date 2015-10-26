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
    
    private static let infoURL = "https://www.youtube.com/get_video_info?video_id="
    private static var userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/46.0.2490.80 Safari/537.36"
    private static let apiKey = "AIzaSyBLTCguAqfQ1K4ejgMQwB0gNTgH4RHA5p8"
    
    static func h264videosWithYoutubeID(youtubeID: String) -> [String: AnyObject]? {
        
        let url = NSURL(string: infoURL + youtubeID)!
        let request = NSMutableURLRequest(URL: url)
        request.timeoutInterval = 5.0
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.HTTPMethod = "GET"
        var responseString = NSString()
        let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
        let group = dispatch_group_create()
        dispatch_group_enter(group)
        session.dataTaskWithRequest(request, completionHandler: { (data, response, _) -> Void in
            if let data = data as NSData? {
                responseString = NSString(data: data, encoding: NSUTF8StringEncoding)!
            }
            dispatch_group_leave(group)
        }).resume()
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER)
        let parts = responseString.dictionaryFromQueryStringComponents()
        if parts.count > 0 {
            var videoTitle: String = ""
            var streamImage: String = ""
            if let title = parts["title"] as? String {
                videoTitle = title
            }
            if let image = parts["iurl"] as? String {
                streamImage = image
            }
            if let fmtStreamMap = parts["url_encoded_fmt_stream_map"] as? String {
                // Live Stream
                if let _: AnyObject = parts["live_playback"]{
                    if let hlsvp = parts["hlsvp"] as? String {
                        return [
                            "url": "\(hlsvp)",
                            "title": "\(videoTitle)",
                            "image": "\(streamImage)",
                            "isStream": true
                        ]
                    }
                } else {
                    let fmtStreamMapArray = fmtStreamMap.componentsSeparatedByString(",")
                    for videoEncodedString in fmtStreamMapArray {
                        var videoComponents = videoEncodedString.dictionaryFromQueryStringComponents()
                        videoComponents["title"] = videoTitle
                        videoComponents["isStream"] = false
                        return videoComponents as [String: AnyObject]
                    }
                }
            }
        }
        return nil
    }
    
    
    
    ///////////////
    
    //could use pagination using nextPageToken? KISS for now
    
    static func getSearchResults(query: String, completionClosure: (results: [YoutubeSearchItem]) -> ()) {
        
        var results = [YoutubeSearchItem]()

        let query = query.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!
        let urlString = "https://www.googleapis.com/youtube/v3/search?part=snippet&maxResults=50&q=\(query)&type=video&key=\(apiKey)"
        let url = NSURL(string: urlString)!
        
        
        NSURLSession.sharedSession().dataTaskWithURL(url) { (data, response, error) -> Void in
            
            let resultsDict = (try! NSJSONSerialization.JSONObjectWithData(data!, options: [])) as! Dictionary<NSObject, AnyObject>
            
            // Get all search result items ("items" array).
            let items: Array<Dictionary<NSObject, AnyObject>> = resultsDict["items"] as! Array<Dictionary<NSObject, AnyObject>>
            
            // Loop through all search results and keep just the necessary data.
            for i in  0..<items.count {
                
                let snippetDict = items[i]["snippet"] as! Dictionary<NSObject, AnyObject>
  
                let title =  snippetDict["title"] as! String
                
                //has 3 thumsb, default seems to be the most appropriet to display in SERPs
                let thumbnail = ((snippetDict["thumbnails"] as! Dictionary<NSObject, AnyObject>)["default"] as! Dictionary<NSObject, AnyObject>)["url"] as! String
                
                let videoId = (items[i]["id"] as! Dictionary<NSObject, AnyObject>)["videoId"] as! String
                
                let live = (snippetDict["liveBroadcastContent"] as! String) == "none" ? false : true
            
                let item = YoutubeSearchItem(title: title, id: videoId, thumbURL: NSURL(string: thumbnail), isLive: live)
                
                results.append(item)
            }
            
            completionClosure(results: results)
        
        }.resume()
        

    }
    
}

public extension NSURL {
    /**
     Parses a query string of an NSURL
     @return key value dictionary with each parameter as an array
     */
    func dictionaryForQueryString() -> [String: AnyObject]? {
        if let query = self.query {
            return query.dictionaryFromQueryStringComponents()
        }
        
        // Note: find youtube ID in m.youtube.com "https://m.youtube.com/#/watch?v=1hZ98an9wjo"
        let result = absoluteString.componentsSeparatedByString("?")
        if result.count > 1 {
            return result.last?.dictionaryFromQueryStringComponents()
        }
        return nil
    }
}

public extension NSString {
    /**
     Convenient method for decoding a html encoded string
     */
    func stringByDecodingURLFormat() -> String {
        let result = self.stringByReplacingOccurrencesOfString("+", withString:" ")
        return result.stringByRemovingPercentEncoding!
    }
    
    /**
     Parses a query string
     @return key value dictionary with each parameter as an array
     */
    func dictionaryFromQueryStringComponents() -> [String: AnyObject] {
        var parameters = [String: AnyObject]()
        for keyValue in componentsSeparatedByString("&") {
            let keyValueArray = keyValue.componentsSeparatedByString("=")
            if keyValueArray.count < 2 {
                continue
            }
            let key = keyValueArray[0].stringByDecodingURLFormat()
            let value = keyValueArray[1].stringByDecodingURLFormat()
            parameters[key] = value
        }
        
        return parameters
    }
}


/////////////

struct YoutubeSearchItem {
    
    let title: String!
    let id: String!
    let thumbURL: NSURL! //has 3, but deqfult, smaller is enogh to display in tableview
    let isLive: Bool!
}




