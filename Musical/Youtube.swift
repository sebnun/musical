//
//  YoutubeParser.swift
//  Musical
//
//  Created by Sebastian on 10/24/15.
//  Copyright © 2015 Sebastian. All rights reserved.
//

import Foundation

class Youtube {
    
    //itags https://en.wikipedia.org/wiki/YouTube#Quality_and_formats
    //can not get file itags data with api
    
    private static let apiKey = "AIzaSyBLTCguAqfQ1K4ejgMQwB0gNTgH4RHA5p8"
    private static var nextPageToken = ""
    
    //need isNewQury cause they can tap search on keyboard to make new quey with same keywords after getting results updating
    static func getSearchResults(query: String, isNewQuery: Bool, maxResults: Int, completionClosure: (results: [YoutubeItemData]) -> ()) {
        
        if isNewQuery {
            nextPageToken = ""
        }
        
        var results = [YoutubeItemData]()
        
        //if is trying to get more results for the same query but last results said it doesnt have more, just return no results
        if !isNewQuery && nextPageToken == "" {
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completionClosure(results: results)
            })
            
            return
        }
        
        if Musical.noInternetWarning() {
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completionClosure(results: results)
            })
            
            return
        }
        
        let query = query.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!
        let urlString = "https://www.googleapis.com/youtube/v3/search?part=snippet&maxResults=\(maxResults)&q=\(query)&type=video&key=\(apiKey)\(nextPageToken == "" ? "" : "&pageToken=" + nextPageToken)"
        let url = NSURL(string: urlString)!
        
        NSURLSession.sharedSession().dataTaskWithURL(url) { (data, response, error) -> Void in
            
            if (error != nil) {
                print("YT SEARCH \(error)")
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    completionClosure(results: results)
                })
                return
            }
            
            if (response as! NSHTTPURLResponse).statusCode != 200 {
                print("YT SEARCH \((response as! NSHTTPURLResponse).statusCode))")
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    completionClosure(results: results)
                })
                return
            }
            
            let json = JSON(data: data!)
            
            //to make pagination in ui, last pages dont have next page token
            if json["nextPageToken"] != nil {
                nextPageToken = json["nextPageToken"].stringValue
            } else {
                nextPageToken = ""
            }
            
            //no results
            if json["items"].count == 0 {
                nextPageToken = ""
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    completionClosure(results: results)
                })
                
                return
            }
            
            var videoIds = ""
            var channelIds = ""
            
            for (_, j) in json["items"] {
                
                let title =  j["snippet"]["title"].stringValue
                let channelId =  j["snippet"]["channelId"].stringValue
                let channelTitle = j["snippet"]["channelTitle"].stringValue
                let thumbnail = j["snippet"]["thumbnails"]["default"]["url"].stringValue //has 3 thumsb, default seems to be the most appropriet to display in SERPs
                let videoId = j["id"]["videoId"].stringValue
                let live = j["snippet"]["liveBroadcastContent"].stringValue == "none" ? false : true
                
                results.append(YoutubeItemData(title: title, channelTitle: channelTitle, id:  videoId, thumbURL: NSURL(string: thumbnail), duration: "", isLive: live, channelId: channelId, isHD: nil, channelBrandTitle: nil, regionsAllowed: nil, regionsBlocked: nil))
                
                videoIds.appendContentsOf("\(videoId),")
                channelIds.appendContentsOf("\(channelId),")
                
            }
            
            videoIds = videoIds.stringByPreparingForYTAPI()
            channelIds = channelIds.stringByPreparingForYTAPI()
            
            let dispatchGroup = dispatch_group_create()
            
            dispatch_group_enter(dispatchGroup)
            getVideosDurationDefinitionRestrictions(videoIds, completionClosure: { (durDef) -> () in
                
                //items.count >= duration.count, some duations can be missing due to youtube api showing results not really avaible in youtube
                for (index, _) in results.enumerate() {
                    
                    results[index].duration = durDef[results[index].id]!.0
                    results[index].isHD = durDef[results[index].id]!.1
                    results[index].regionsAllowed = durDef[results[index].id]!.2
                    results[index].regionsBlocked =  durDef[results[index].id]!.3
                }
                
                dispatch_group_leave(dispatchGroup)
            })
            
            dispatch_group_enter(dispatchGroup)
            getVideosChannelBrandTitle(channelIds, completionClosure: { (brandTitles) -> () in
                
                for (index, _) in results.enumerate() {
                    results[index].channelBrandTitle = brandTitles[results[index].channelId]!
                }
                
                dispatch_group_leave(dispatchGroup)
            })
            
            dispatch_group_notify(dispatchGroup, dispatch_get_main_queue(), { () -> Void in
                
                //duration data retuned might be less count than results from search api, video not in youtube, remove it
                //live video crashes vimplayer and mpmediacenter second counting, some items have islive = false but they are live
                results = results.filter({ $0.duration != "" && !$0.isLive && $0.duration != "0:00" })

                //filter restricted content
                results = results.filter({ $0.regionsAllowed != nil ? $0.regionsAllowed!.contains(Musical.countryCode) : true })
                results = results.filter({ $0.regionsBlocked != nil ? !$0.regionsBlocked!.contains(Musical.countryCode) : true })
                
                completionClosure(results: results)
            })
            
        }.resume()
    }
    
    
    //when a video is not avaible, it doesnt return any error, less itemms than videosIds passed
    private static func getVideosDurationDefinitionRestrictions(videoIds: String, completionClosure: (durDef: [String: (String, Bool, [String]?, [String]?)]) -> ()) {
        
        //videoid: (duration, isHd, regionallowed, regionblocked)
        var durDef = [String: (String, Bool, [String]?, [String]?)]()
        
        let urlString = "https://www.googleapis.com/youtube/v3/videos?part=contentDetails&id=\(videoIds)&key=\(apiKey)"
        let url = NSURL(string: urlString)!
        
        NSURLSession.sharedSession().dataTaskWithURL(url) { (data, response, error) -> Void in
            
            if (error != nil) {
                print("YT DURATION \(error)")
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    completionClosure(durDef: durDef)
                })
                return
            }
            
            if (response as! NSHTTPURLResponse).statusCode != 200 {
                print("YT DUARTION \((response as! NSHTTPURLResponse).statusCode))")
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    completionClosure(durDef: durDef)
                })
                return
            }
            
            let json = JSON(data: data!)
            for (_, j) in json["items"] {
                
                var regionAllowed: [String]? = nil
                var regionBlocked: [String]? = nil
                
                let videoId = j["id"].stringValue
                let duration = j["contentDetails"]["duration"].stringValue.stringFromISO8601Duration()
                let isHD = j["contentDetails"]["definition"].stringValue == "sd" ? false : true
                
                //"The object will contain either the contentDetails.regionRestriction.allowed property or the contentDetails.regionRestriction.blocked property"
                
                if j["contentDetails"]["regionRestriction"]["allowed"] != nil {
                    regionAllowed = [String]()
                    
                    for region in j["contentDetails"]["regionRestriction"]["allowed"] {
                        regionAllowed?.append(region.1.stringValue)
                    }
                } else if j["contentDetails"]["regionRestriction"]["blocked"] != nil {
                    regionBlocked = [String]()
                    
                    for region in j["contentDetails"]["regionRestriction"]["blocked"] {
                        regionBlocked?.append(region.1.stringValue)
                    }
                }
                
                durDef[videoId] = (duration, isHD, regionAllowed, regionBlocked)
            }
            
            completionClosure(durDef: durDef)
            
        }.resume()
    }
    
    private static func getVideosChannelBrandTitle(channelIds: String, completionClosure: (brandTitles: [String: String?]) -> ()) {
        
        // channelId: channelBrand
        var brandTitles = [String: String?]()
        
        let urlString = "https://www.googleapis.com/youtube/v3/channels?part=brandingSettings&id=\(channelIds)&key=\(apiKey)"
        let url = NSURL(string: urlString)!
        
        NSURLSession.sharedSession().dataTaskWithURL(url) { (data, response, error) -> Void in
            
            if (error != nil) {
                print("YT BRAND \(error)")
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    completionClosure(brandTitles: brandTitles)
                })
                return
            }
            
            if (response as! NSHTTPURLResponse).statusCode != 200 {
                print("YT BRAND \((response as! NSHTTPURLResponse).statusCode))")
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    completionClosure(brandTitles: brandTitles)
                })
                return
            }
            
            let json = JSON(data: data!)
            for (_, j) in json["items"] {
                
                let channelId = j["id"].stringValue
                let brandTitle = j["brandingSettings"]["channel"]["title"].string //can be nil
                
                brandTitles[channelId] = brandTitle
            }
            
            completionClosure(brandTitles: brandTitles)
            
        }.resume()
    }
    
    //can return some videos that are not really avaible in youtube, they appear in this api, but not in duration api
    static func getPlaylistsSinppet(playlists: [String], completionClosure: (playlistsSnippets: [(title: String, thumbUrl: NSURL)]) -> ()) {
        
        var playlistsSnippets = [(title: String, thumbUrl: NSURL)]()
        
        if Musical.noInternetWarning() {
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completionClosure(playlistsSnippets: playlistsSnippets)
            })
            
            return
        }
        
        var playlistIds = ""
        
        for id in playlists {
            playlistIds += id + ","
        }
        
        playlistIds = playlistIds.stringByPreparingForYTAPI()
        
        let urlString = "https://www.googleapis.com/youtube/v3/playlists?part=snippet&id=\(playlistIds)&key=\(apiKey)"
        let url = NSURL(string: urlString)!
        
        NSURLSession.sharedSession().dataTaskWithURL(url) { (data, response, error) -> Void in
            
            if (error != nil) {
                print("YT PLSNIPPETS \(error)")
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    completionClosure(playlistsSnippets: playlistsSnippets)
                })
                return
            }
            
            if (response as! NSHTTPURLResponse).statusCode != 200 {
                print("YT PLAYLSSIPPETS \((response as! NSHTTPURLResponse).statusCode))")
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    completionClosure(playlistsSnippets: playlistsSnippets)
                })
                return
            }
                
            let json = JSON(data: data!)
                
            for (_, j) in json["items"] {
                    
                let title = j["snippet"]["title"].stringValue
                let thumbURL = NSURL(string: j["snippet"]["thumbnails"]["default"]["url"].string!) //some playlist dont have maxres, and gets ugly in tableview iwth different siezes
                
                playlistsSnippets.append((title, thumbURL!))
            }
            
            completionClosure(playlistsSnippets: playlistsSnippets)
            
        }.resume()
    }
    
    private static let maxItems = 50
    
    static func getPlaylistItems(id: String, completionClosure: (items: [YoutubeItemData]) -> ()) {
        
        let urlString = "https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&maxResults=\(maxItems)&playlistId=\(id)&key=\(apiKey)"
        let url = NSURL(string: urlString)!
        
        var items = [YoutubeItemData]()
        
        if Musical.noInternetWarning() {
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completionClosure(items: items)
            })
            
            return
        }

        NSURLSession.sharedSession().dataTaskWithURL(url) { (data, response, error) -> Void in
            
            if (error != nil) {
                print("YT PLAYLIST ITEM \(error)")
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    completionClosure(items: items)
                })
                return
                
            } else if (response as! NSHTTPURLResponse).statusCode != 200 {
                print("YT PLAYLIST ITEM \((response as! NSHTTPURLResponse).statusCode))")
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    completionClosure(items: items)
                })
                return
            }
            
            var videoIds = ""
            
            let json = JSON(data: data!)
            
            for (_, j) in json["items"] {
                
                let title = j["snippet"]["title"].stringValue
                let channelTitle = j["snippet"]["channelTitle"].stringValue //from the playlits api the channel title is autogenerated like #music, leave it as is, better experience
                let thumbnail = j["snippet"]["thumbnails"]["default"]["url"].stringValue
                let videoId = j["snippet"]["resourceId"]["videoId"].stringValue
                
                items.append(YoutubeItemData(title: title, channelTitle: channelTitle, id: videoId, thumbURL: NSURL(string: thumbnail), duration: "", isLive: false, channelId: "", isHD: false, channelBrandTitle: nil, regionsAllowed: nil, regionsBlocked: nil))
                
                videoIds.appendContentsOf("\(videoId),")
            }
            
            videoIds = videoIds.stringByPreparingForYTAPI()
            
            let dispatchGroup = dispatch_group_create()
            dispatch_group_enter(dispatchGroup)
            getVideosDurationDefinitionRestrictions(videoIds, completionClosure: { (durDef) -> () in
                
                //items.count >= duration.count, some duations can be missing due to youtube api showing results not really avaible in youtube
                for (index, _) in items.enumerate() {
                    
                    items[index].duration = durDef[items[index].id]!.0
                    items[index].isHD = durDef[items[index].id]!.1
                    items[index].regionsAllowed = durDef[items[index].id]!.2
                    items[index].regionsBlocked = durDef[items[index].id]!.3
                }
                
                dispatch_group_leave(dispatchGroup)
            })
            
            dispatch_group_notify(dispatchGroup, dispatch_get_main_queue(), { () -> Void in
                
                //duration data retuned might be less count than results from search api, video not in youtube, remove it
                //live video crashes vimplayer and mpmediacenter second counting, some items have islive = false but they are live
                items = items.filter({ $0.duration != "" && $0.duration != "0:00" })
                
                //filter restricted content
                items = items.filter({ $0.regionsAllowed != nil ? $0.regionsAllowed!.contains(Musical.countryCode) : true })
                items = items.filter({ $0.regionsBlocked != nil ? !$0.regionsBlocked!.contains(Musical.countryCode) : true })
                
                completionClosure(items: items)
            })
            
        }.resume()
    }
    
    //http://shreyaschand.com/blog/2013/01/03/google-autocomplete-api/
    static func getSearchSuggestions(query: String, lang: String, completionHandler: (suggestions: [String]) -> ()) {
        
        var suggestions = [String]()
        
        //just dont show anything and wanr on search
        
        if !Musical.reachability.isReachable() {
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completionHandler(suggestions: suggestions)
            })
                
            return
        }
        
        let query = query.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!
        let urlString = "http://suggestqueries.google.com/complete/search?q=\(query)&client=firefox&hl=\(lang)&ds=yt"
        let url = NSURL(string: urlString)!
        
        NSURLSession.sharedSession().dataTaskWithURL(url) { (data, response, error) -> Void in
            
            if (error != nil) {
                print("YT SUGGESTION \(error)")
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    completionHandler(suggestions: suggestions)
                })
                return
            }
            
            if (response as! NSHTTPURLResponse).statusCode != 200 {
                print("YT SUGESSTION \((response as! NSHTTPURLResponse).statusCode)")
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    completionHandler(suggestions: suggestions)
                })
                return
            }
            
            let json = JSON(data: data!)
            
            for (_, suggestion) in json[1] {
                suggestions.append(suggestion.stringValue)
            }
            
            completionHandler(suggestions: suggestions)
            
        }.resume()
    }
    
}

struct YoutubeItemData {
    
    let title: String! //from search api
    let channelTitle: String! //from search api, can be empty, not the real one dispplayed on youtube ui
    let id: String! //from search api
    let thumbURL: NSURL! //from searcvh api, has 3 but default is enogh to display in tableview
    var duration: String! //video,contenDetails api
    let isLive: Bool! //from search api .. notactuall used
    let channelId: String! //from search api
    var isHD: Bool! //from video,contenDetails api
    var channelBrandTitle: String? // from channel,brandingSettings.channel.title api
    var regionsAllowed: [String]? //from video api
    var regionsBlocked: [String]? //from video api
}

extension String {
    
    func stringFromISO8601Duration() -> String {
        
        let duration = self as NSString
        
        let secRegex = try! NSRegularExpression(pattern: "(\\d+)S", options: [])
        let secsRange = secRegex.firstMatchInString(self, options: [], range: NSMakeRange(0, self.utf16.count))?.range
        
        let minRegex = try! NSRegularExpression(pattern: "(\\d+)M", options: [])
        let minsRange = minRegex.firstMatchInString(self, options: [], range: NSMakeRange(0, self.utf16.count))?.range
        
        let hourRegex = try! NSRegularExpression(pattern: "(\\d+)H", options: [])
        let hoursRange = hourRegex.firstMatchInString(self, options: [], range: NSMakeRange(0, self.utf16.count))?.range
        
        let dayRegex = try! NSRegularExpression(pattern: "(\\d+)DT", options: [])
        let daysRange = dayRegex.firstMatchInString(self, options: [], range: NSMakeRange(0, self.utf16.count))?.range
        
        
        var days = ""
        
        if daysRange != nil {
            
            days = duration.substringWithRange(daysRange!).stringByReplacingOccurrencesOfString("DT", withString: ":")
        }
        
        var hours = ""
        
        if hoursRange != nil {
            hours = duration.substringWithRange(hoursRange!).stringByReplacingOccurrencesOfString("H", withString: ":")
            
            if hours.characters.count == 2 && daysRange != nil { //1 num + :
                hours = "0" + hours
            }
            
        } else if hoursRange == nil && daysRange != nil {
            hours = "00:"
        }
        
        var mins = ""
        
        if minsRange != nil {
            mins = duration.substringWithRange(minsRange!).stringByReplacingOccurrencesOfString("M", withString: ":")
            
            if mins.characters.count == 2 && hoursRange != nil {
                mins = "0" + mins
            }
            
        } else if minsRange == nil && hoursRange != nil {
            mins = "00:"
        }
        
        var secs = "" //secs can be missing
        
        if secsRange != nil {
            secs = duration.substringWithRange(secsRange!).stringByReplacingOccurrencesOfString("S", withString: "")
            
            if secs.characters.count == 1 {
                secs = "0" + secs
            }
        } else {
            secs = "00"
        }
        
        if daysRange == nil && hoursRange == nil && minsRange == nil {
            secs = "0:" + secs
        }
        
        return days + hours + mins + secs
        
    }
    
    func stringByPreparingForYTAPI() -> String {
        
        var stringEncoded = self.stringByReplacingOccurrencesOfString(",", withString: "%2C")
        stringEncoded.removeAtIndex(stringEncoded.endIndex.predecessor())
        stringEncoded.removeAtIndex(stringEncoded.endIndex.predecessor())
        stringEncoded.removeAtIndex(stringEncoded.endIndex.predecessor())
        
        return stringEncoded
    }
    
}



