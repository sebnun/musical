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
    
    static func play () {
        Musical.popupContentController.popupItem.leftBarButtonItems![0].image = UIImage(named: "NowPlayingTransportControlPause")
        Musical.videoPlayerView.player.play()
    }
    
    static func pause () {
        Musical.popupContentController.popupItem.leftBarButtonItems![0].image = UIImage(named: "NowPlayingTransportControlPlay")
        Musical.videoPlayerView.player.pause()
    }
    
    //can this fail?
    static let reachability = try! Reachability.reachabilityForInternetConnection()
    
    static let color = UIColor.redColor()
    
    static func noInternetWarning() -> Bool {
        
        if !reachability.isReachable() {
        
            let alert = UIAlertController(title: NSLocalizedString("No internet connection", comment: "") , message: NSLocalizedString("Connect to the internet and try again.", comment: ""), preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
            UIApplication.sharedApplication().keyWindow?.rootViewController?.presentViewController(alert, animated: true, completion: nil)
            
            return true
            
        } else {
            return false
        }
    }
    
    static func presentPlayer(item: YoutubeItemData) {
        
        if Musical.popupContentController == nil {
            Musical.popupContentController = UIApplication.sharedApplication().keyWindow?.rootViewController?.storyboard?.instantiateViewControllerWithIdentifier("playerViewController") as! PlayerViewController
            
            Musical.popupContentController.videoTitle = item.title
            Musical.popupContentController.videoId = item.id
            Musical.popupContentController.videoChannelTitle = item.channelBrandTitle ?? item.channelTitle
            
            UIApplication.sharedApplication().keyWindow?.rootViewController!.presentPopupBarWithContentViewController(Musical.popupContentController, openPopup: true, animated: true, completion: nil)
        } else {
            
            Musical.popupContentController.videoTitle = item.title
            Musical.popupContentController.videoId = item.id
            Musical.popupContentController.videoChannelTitle = item.channelBrandTitle ?? item.channelTitle
            
            Musical.popupContentController.setupForNewVideo()
            UIApplication.sharedApplication().keyWindow?.rootViewController?.openPopupAnimated(true, completion: nil)
        }
    }
    
}

