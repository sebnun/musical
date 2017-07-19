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
    
    fileprivate static let apiKey = "AIzaSyBLTCguAqfQ1K4ejgMQwB0gNTgH4RHA5p8"
    fileprivate static var nextPageToken = ""
    
    //need isNewQury cause they can tap search on keyboard to make new quey with same keywords after getting results updating
    static func getSearchResults(_ query: String, isNewQuery: Bool, maxResults: Int, completionClosure: @escaping (_ results: [YoutubeItemData]) -> ()) {
        
        if isNewQuery {
            nextPageToken = ""
        }
        
        var results = [YoutubeItemData]()
        
        //if is trying to get more results for the same query but last results said it doesnt have more, just return no results
        if !isNewQuery && nextPageToken == "" {
            
            DispatchQueue.main.async(execute: { () -> Void in
                completionClosure(results)
            })
            
            return
        }
        
        if Musical.noInternetWarning() {
            
            DispatchQueue.main.async(execute: { () -> Void in
                completionClosure(results)
            })
            
            return
        }
        
        let query = query.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        let urlString = "https://www.googleapis.com/youtube/v3/search?part=snippet&maxResults=\(maxResults)&q=\(query)&type=video&key=\(apiKey)\(nextPageToken == "" ? "" : "&pageToken=" + nextPageToken)"
        let url = URL(string: urlString)!
        
        URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) -> Void in
            
            if (error != nil) {
                print("YT SEARCH \(error)")
                DispatchQueue.main.async(execute: { () -> Void in
                    completionClosure(results)
                })
                return
            }
            
            if (response as! HTTPURLResponse).statusCode != 200 {
                print("YT SEARCH \((response as! HTTPURLResponse).statusCode))")
                DispatchQueue.main.async(execute: { () -> Void in
                    completionClosure(results)
                })
                return
            }
            
            let json = try! JSON(data: data!)
            
            //to make pagination in ui, last pages dont have next page token
            if json["nextPageToken"] != nil {
                nextPageToken = json["nextPageToken"].stringValue
            } else {
                nextPageToken = ""
            }
            
            //no results
            if json["items"].count == 0 {
                nextPageToken = ""
                
                DispatchQueue.main.async(execute: { () -> Void in
                    completionClosure(results)
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
                
                results.append(YoutubeItemData(title: title, channelTitle: channelTitle, id:  videoId, thumbURL: URL(string: thumbnail), duration: "", isLive: live, channelId: channelId, isHD: nil, channelBrandTitle: nil, regionsAllowed: nil, regionsBlocked: nil))
                
                videoIds.append("\(videoId),")
                channelIds.append("\(channelId),")
                
            }
            
            videoIds = videoIds.stringByPreparingForYTAPI()
            channelIds = channelIds.stringByPreparingForYTAPI()
            
            let dispatchGroup = DispatchGroup()
            
            dispatchGroup.enter()
            getVideosDurationDefinitionRestrictions(videoIds, completionClosure: { (durDef) -> () in
                
                //items.count >= duration.count, some duations can be missing due to youtube api showing results not really avaible in youtube
                for (index, _) in results.enumerated() {
                    
                    results[index].duration = durDef[results[index].id]!.0
                    results[index].isHD = durDef[results[index].id]!.1
                    results[index].regionsAllowed = durDef[results[index].id]!.2
                    results[index].regionsBlocked =  durDef[results[index].id]!.3
                }
                
                dispatchGroup.leave()
            })
            
            dispatchGroup.enter()
            getVideosChannelBrandTitle(channelIds, completionClosure: { (brandTitles) -> () in
                
                for (index, _) in results.enumerated() {
                    results[index].channelBrandTitle = brandTitles[results[index].channelId]!
                }
                
                dispatchGroup.leave()
            })
            
            dispatchGroup.notify(queue: DispatchQueue.main, execute: { () -> Void in
                
                //duration data retuned might be less count than results from search api, video not in youtube, remove it
                //live video crashes vimplayer and mpmediacenter second counting, some items have islive = false but they are live
                results = results.filter({ $0.duration != "" && !$0.isLive && $0.duration != "0:00" })

                //filter restricted content
                results = results.filter({ $0.regionsAllowed != nil ? $0.regionsAllowed!.contains(Musical.countryCode) : true })
                results = results.filter({ $0.regionsBlocked != nil ? !$0.regionsBlocked!.contains(Musical.countryCode) : true })
                
                completionClosure(results)
            })
            
        }) .resume()
    }
    
    
    //when a video is not avaible, it doesnt return any error, less itemms than videosIds passed
    fileprivate static func getVideosDurationDefinitionRestrictions(_ videoIds: String, completionClosure: @escaping (_ durDef: [String: (String, Bool, [String]?, [String]?)]) -> ()) {
        
        //videoid: (duration, isHd, regionallowed, regionblocked)
        var durDef = [String: (String, Bool, [String]?, [String]?)]()
        
        let urlString = "https://www.googleapis.com/youtube/v3/videos?part=contentDetails&id=\(videoIds)&key=\(apiKey)"
        let url = URL(string: urlString)!
        
        URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) -> Void in
            
            if (error != nil) {
                print("YT DURATION \(error)")
                DispatchQueue.main.async(execute: { () -> Void in
                    completionClosure(durDef)
                })
                return
            }
            
            if (response as! HTTPURLResponse).statusCode != 200 {
                print("YT DUARTION \((response as! HTTPURLResponse).statusCode))")
                DispatchQueue.main.async(execute: { () -> Void in
                    completionClosure(durDef)
                })
                return
            }
            
            let json = try! JSON(data: data!)
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
            
            completionClosure(durDef)
            
        }) .resume()
    }
    
    fileprivate static func getVideosChannelBrandTitle(_ channelIds: String, completionClosure: @escaping (_ brandTitles: [String: String?]) -> ()) {
        
        // channelId: channelBrand
        var brandTitles = [String: String?]()
        
        let urlString = "https://www.googleapis.com/youtube/v3/channels?part=brandingSettings&id=\(channelIds)&key=\(apiKey)"
        let url = URL(string: urlString)!
        
        URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) -> Void in
            
            if (error != nil) {
                print("YT BRAND \(error)")
                DispatchQueue.main.async(execute: { () -> Void in
                    completionClosure(brandTitles)
                })
                return
            }
            
            if (response as! HTTPURLResponse).statusCode != 200 {
                print("YT BRAND \((response as! HTTPURLResponse).statusCode))")
                DispatchQueue.main.async(execute: { () -> Void in
                    completionClosure(brandTitles)
                })
                return
            }
            
            let json = try! JSON(data: data!)
            for (_, j) in json["items"] {
                
                let channelId = j["id"].stringValue
                let brandTitle = j["brandingSettings"]["channel"]["title"].string //can be nil
                
                brandTitles[channelId] = brandTitle
            }
            
            completionClosure(brandTitles)
            
        }) .resume()
    }
    
    //can return some videos that are not really avaible in youtube, they appear in this api, but not in duration api
    static func getPlaylistsSinppet(_ playlists: [String], completionClosure: @escaping (_ playlistsSnippets: [(title: String, thumbUrl: URL)]) -> ()) {
        
        var playlistsSnippets = [(title: String, thumbUrl: URL)]()
        
        if Musical.noInternetWarning() {
            
            DispatchQueue.main.async(execute: { () -> Void in
                completionClosure(playlistsSnippets)
            })
            
            return
        }
        
        var playlistIds = ""
        
        for id in playlists {
            playlistIds += id + ","
        }
        
        playlistIds = playlistIds.stringByPreparingForYTAPI()
        
        let urlString = "https://www.googleapis.com/youtube/v3/playlists?part=snippet&id=\(playlistIds)&key=\(apiKey)"
        let url = URL(string: urlString)!
        
        URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) -> Void in
            
            if (error != nil) {
                print("YT PLSNIPPETS \(error)")
                DispatchQueue.main.async(execute: { () -> Void in
                    completionClosure(playlistsSnippets)
                })
                return
            }
            
            if (response as! HTTPURLResponse).statusCode != 200 {
                print("YT PLAYLSSIPPETS \((response as! HTTPURLResponse).statusCode))")
                DispatchQueue.main.async(execute: { () -> Void in
                    completionClosure(playlistsSnippets)
                })
                return
            }
                
            let json = try! JSON(data: data!)
                
            for (_, j) in json["items"] {
                    
                let title = j["snippet"]["title"].stringValue
                let thumbURL = URL(string: j["snippet"]["thumbnails"]["default"]["url"].string!) //some playlist dont have maxres, and gets ugly in tableview iwth different siezes
                
                playlistsSnippets.append((title, thumbURL!))
            }
            
            completionClosure(playlistsSnippets)
            
        }) .resume()
    }
    
    fileprivate static let maxItems = 50
    
    static func getPlaylistItems(_ id: String, completionClosure: @escaping (_ items: [YoutubeItemData]) -> ()) {
        
        let urlString = "https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&maxResults=\(maxItems)&playlistId=\(id)&key=\(apiKey)"
        let url = URL(string: urlString)!
        
        var items = [YoutubeItemData]()
        
        if Musical.noInternetWarning() {
            
            DispatchQueue.main.async(execute: { () -> Void in
                completionClosure(items)
            })
            
            return
        }

        URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) -> Void in
            
            if (error != nil) {
                print("YT PLAYLIST ITEM \(error)")
                DispatchQueue.main.async(execute: { () -> Void in
                    completionClosure(items)
                })
                return
                
            } else if (response as! HTTPURLResponse).statusCode != 200 {
                print("YT PLAYLIST ITEM \((response as! HTTPURLResponse).statusCode))")
                DispatchQueue.main.async(execute: { () -> Void in
                    completionClosure(items)
                })
                return
            }
            
            var videoIds = ""
            
            let json = try! JSON(data: data!)
            
            for (_, j) in json["items"] {
                
                let title = j["snippet"]["title"].stringValue
                let channelTitle = j["snippet"]["channelTitle"].stringValue //from the playlits api the channel title is autogenerated like #music, leave it as is, better experience
                let thumbnail = j["snippet"]["thumbnails"]["default"]["url"].stringValue
                let videoId = j["snippet"]["resourceId"]["videoId"].stringValue
                
                items.append(YoutubeItemData(title: title, channelTitle: channelTitle, id: videoId, thumbURL: URL(string: thumbnail), duration: "", isLive: false, channelId: "", isHD: false, channelBrandTitle: nil, regionsAllowed: nil, regionsBlocked: nil))
                
                videoIds.append("\(videoId),")
            }
            
            videoIds = videoIds.stringByPreparingForYTAPI()
            
            let dispatchGroup = DispatchGroup()
            dispatchGroup.enter()
            getVideosDurationDefinitionRestrictions(videoIds, completionClosure: { (durDef) -> () in
                
                //items.count >= duration.count, some duations can be missing due to youtube api showing results not really avaible in youtube
                for (index, _) in items.enumerated() {
                    
                    items[index].duration = durDef[items[index].id]!.0
                    items[index].isHD = durDef[items[index].id]!.1
                    items[index].regionsAllowed = durDef[items[index].id]!.2
                    items[index].regionsBlocked = durDef[items[index].id]!.3
                }
                
                dispatchGroup.leave()
            })
            
            dispatchGroup.notify(queue: DispatchQueue.main, execute: { () -> Void in
                
                //duration data retuned might be less count than results from search api, video not in youtube, remove it
                //live video crashes vimplayer and mpmediacenter second counting, some items have islive = false but they are live
                items = items.filter({ $0.duration != "" && $0.duration != "0:00" })
                
                //filter restricted content
                items = items.filter({ $0.regionsAllowed != nil ? $0.regionsAllowed!.contains(Musical.countryCode) : true })
                items = items.filter({ $0.regionsBlocked != nil ? !$0.regionsBlocked!.contains(Musical.countryCode) : true })
                
                completionClosure(items)
            })
            
        }) .resume()
    }
    
    //http://shreyaschand.com/blog/2013/01/03/google-autocomplete-api/
    static func getSearchSuggestions(_ query: String, lang: String, completionHandler: @escaping (_ suggestions: [String]) -> ()) {
        
        var suggestions = [String]()
        
        //just dont show anything and wanr on search
        
        if !Musical.reachability!.isReachable {
            
            DispatchQueue.main.async(execute: { () -> Void in
                completionHandler(suggestions)
            })
                
            return
        }
        
        let query = query.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        let urlString = "http://suggestqueries.google.com/complete/search?q=\(query)&client=firefox&hl=\(lang)&ds=yt"
        let url = URL(string: urlString)!
        
        URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) -> Void in
            
            if (error != nil) {
                print("YT SUGGESTION \(error)")
                DispatchQueue.main.async(execute: { () -> Void in
                    completionHandler(suggestions)
                })
                return
            }
            
            if (response as! HTTPURLResponse).statusCode != 200 {
                print("YT SUGESSTION \((response as! HTTPURLResponse).statusCode)")
                DispatchQueue.main.async(execute: { () -> Void in
                    completionHandler(suggestions)
                })
                return
            }
            
            let json = try! JSON(data: data!)
            
            for (_, suggestion) in json[1] {
                suggestions.append(suggestion.stringValue)
            }
            
            completionHandler(suggestions)
            
        }) .resume()
    }
    
}

struct YoutubeItemData {
    
    let title: String! //from search api
    let channelTitle: String! //from search api, can be empty, not the real one dispplayed on youtube ui
    let id: String! //from search api
    let thumbURL: URL! //from searcvh api, has 3 but default is enogh to display in tableview
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
        let secsRange = secRegex.firstMatch(in: self, options: [], range: NSMakeRange(0, self.utf16.count))?.range
        
        let minRegex = try! NSRegularExpression(pattern: "(\\d+)M", options: [])
        let minsRange = minRegex.firstMatch(in: self, options: [], range: NSMakeRange(0, self.utf16.count))?.range
        
        let hourRegex = try! NSRegularExpression(pattern: "(\\d+)H", options: [])
        let hoursRange = hourRegex.firstMatch(in: self, options: [], range: NSMakeRange(0, self.utf16.count))?.range
        
        let dayRegex = try! NSRegularExpression(pattern: "(\\d+)DT", options: [])
        let daysRange = dayRegex.firstMatch(in: self, options: [], range: NSMakeRange(0, self.utf16.count))?.range
        
        
        var days = ""
        
        if daysRange != nil {
            
            days = duration.substring(with: daysRange!).replacingOccurrences(of: "DT", with: ":")
        }
        
        var hours = ""
        
        if hoursRange != nil {
            hours = duration.substring(with: hoursRange!).replacingOccurrences(of: "H", with: ":")
            
            if hours.characters.count == 2 && daysRange != nil { //1 num + :
                hours = "0" + hours
            }
            
        } else if hoursRange == nil && daysRange != nil {
            hours = "00:"
        }
        
        var mins = ""
        
        if minsRange != nil {
            mins = duration.substring(with: minsRange!).replacingOccurrences(of: "M", with: ":")
            
            if mins.characters.count == 2 && hoursRange != nil {
                mins = "0" + mins
            }
            
        } else if minsRange == nil && hoursRange != nil {
            mins = "00:"
        }
        
        var secs = "" //secs can be missing
        
        if secsRange != nil {
            secs = duration.substring(with: secsRange!).replacingOccurrences(of: "S", with: "")
            
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
        
        var stringEncoded = self.replacingOccurrences(of: ",", with: "%2C")
        stringEncoded.remove(at: stringEncoded.characters.index(before: stringEncoded.endIndex))
        stringEncoded.remove(at: stringEncoded.characters.index(before: stringEncoded.endIndex))
        stringEncoded.remove(at: stringEncoded.characters.index(before: stringEncoded.endIndex))
        
        return stringEncoded
    }
    
}



