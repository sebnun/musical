//
//  Model.swift
//  Musical
//
//  Created by Sebastian on 11/23/15.
//  Copyright © 2015 Sebastian. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit
import MediaPlayer

class Musical {
    
    static var popupContentController: PlayerViewController!
    static var videoPlayerView: VIMVideoPlayerView!
    static var countryCode: String!
    
    static func play () {
        Musical.popupContentController.popupItem.leftBarButtonItems![0].image = UIImage(named: "NowPlayingTransportControlPause")
        Musical.videoPlayerView.player.play()
    }
    
    static func pause () {
        Musical.popupContentController.popupItem.leftBarButtonItems![0].image = UIImage(named: "NowPlayingTransportControlPlay")
        Musical.videoPlayerView.player.pause()
    }
    
    //can this fail?
    static let reachability =  Reachability()
    
    static let color = UIColor.red
    
    static func noInternetWarning() -> Bool {
        
        if !reachability!.isReachable {
        
            let alert = UIAlertController(title: NSLocalizedString("No internet connection", comment: "") , message: NSLocalizedString("Connect to the internet and try again.", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
            
            return true
            
        } else {
            return false
        }
    }
    
    static func presentPlayer(_ item: YoutubeItemData) {
        
        if Musical.popupContentController == nil {
            
            Musical.popupContentController = UIApplication.shared.keyWindow?.rootViewController?.storyboard?.instantiateViewController(withIdentifier: "playerViewController") as! PlayerViewController
            
            Musical.popupContentController.videoTitle = item.title
            Musical.popupContentController.videoId = item.id
            Musical.popupContentController.videoChannelTitle = item.channelBrandTitle ?? item.channelTitle
            
            UIApplication.shared.keyWindow?.rootViewController!.presentPopupBar(withContentViewController: Musical.popupContentController, openPopup: true, animated: true, completion: nil)
        } else {
            
            Musical.popupContentController.videoTitle = item.title
            Musical.popupContentController.videoId = item.id
            Musical.popupContentController.videoChannelTitle = item.channelBrandTitle ?? item.channelTitle
            
            Musical.popupContentController.setupForNewVideo()
            UIApplication.shared.keyWindow?.rootViewController?.openPopup(animated: true, completion: nil)
        }
    }
    
    
    //TODO: really have to test this with dirrent connections to see if countrycode is complatibel with youtube countrycode format
    static func getConnectionCountryCode(_ completionHandler: @escaping (_ countryCode: String) -> ()) {
        
        let urlString = "http://ip-api.com/json"
        let url = URL(string: urlString)!
        
        URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) -> Void in
            
            if (error != nil) {
                //get country code of device, might be the same as the connection
                completionHandler((Locale.current as NSLocale).object(forKey: NSLocale.Key.countryCode) as! String)
                return
            }
            
            let json = try! JSON(data: data!)
            let countryCode = json["countryCode"].stringValue
            
            completionHandler(countryCode)
            
        }) .resume()
        
    }
    
}

