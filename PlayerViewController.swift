//
//  PlayerViewController.swift
//  Musical
//
//  Created by Sebastian on 10/24/15.
//  Copyright © 2015 Sebastian. All rights reserved.
//

import UIKit
import LNPopupController
import XCDYouTubeKit
import AVKit
import AVFoundation

class PlayerViewController: UIViewController {
    
    var videoTitle: String!
    var channelTitle: String!
    var videoId: String!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //for backround audio
        try! AVAudioSession.sharedInstance().setActive(true)
        try! AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
        
//        if NSClassFromString("MPNowPlayingInfoCenter") != nil {
//            let image:UIImage = UIImage(named: "logo_player_background")!
//            let albumArt = MPMediaItemArtwork(image: image)
//            let songInfo: NSMutableDictionary = [
//                MPMediaItemPropertyTitle: "Radio Brasov",
//                MPMediaItemPropertyArtist: "87,8fm",
//                MPMediaItemPropertyArtwork: albumArt
//            ]
//            
//            MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = songInfo as [NSObject : AnyObject]?
//        }

        
        popupItem.title = videoTitle
        popupItem.subtitle = channelTitle
        
        //get thumb using api, directly using http://img./youtubeid/..  for kingfisher handling or with hcyoutubeparser
        
        XCDYouTubeClient.defaultClient().getVideoWithIdentifier(videoId) { (video, error) -> Void in
            
            let url = video!.streamURLs[18] as! NSURL
            
            var items = [AVPlayerItem]()
            
            items.append(AVPlayerItem(URL: url))

            player = AVQueuePlayer(items: items)
            playerLayer = AVPlayerLayer(player: player)
            playerLayer.frame = self.view.bounds
            self.view.layer.addSublayer(playerLayer)
            player.play()
        }
        
        //NSNotificationCenter.defaultCenter().addObserver(self, selector:"applicationDidEnterBackground:", name: UIApplicationDidEnterBackgroundNotification, object: nil)
        
    }
    
    //for backround audio
    
//    override func viewWillAppear(animated: Bool) {
//        UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
//        self.becomeFirstResponder()
//    }
//
//    
//    override func viewWillDisappear(animated: Bool) {
//        player.pause()
//        UIApplication.sharedApplication().endReceivingRemoteControlEvents()
//        self.resignFirstResponder()
//    }
    
//    override func remoteControlReceivedWithEvent(event: UIEvent?) {
//        switch event!.subtype {
//            
//        case .RemoteControlTogglePlayPause:
//            
//            if player.rate == 0 {
//                player.play()
//            } else {
//                player.pause()
//            }
//            break
//        case .RemoteControlPlay:
//            player.play()
//            break
//        case .RemoteControlPause:
//            player.pause()
//            break
//        default:
//            break
//        }
//    }
//
//    func applicationDidEnterBackground(notification: NSNotification) {
//        player.performSelector("play", withObject: nil, afterDelay: 0.01)
//    }
//    
//    func play() {
//        player.play()
//    }
//    
//    deinit {
//        UIApplication.sharedApplication().endReceivingRemoteControlEvents()
//        NSNotificationCenter.defaultCenter().removeObserver(self)
//    }

}
