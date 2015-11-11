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
    
    var player: AVPlayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //for backround audio
        try! AVAudioSession.sharedInstance().setActive(true)
        try! AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        
        
        popupItem.title = videoTitle
        popupItem.subtitle = channelTitle
        
        //get thumb using api, directly using http://img./youtubeid/..  for kingfisher handling or with hcyoutubeparser
        
        XCDYouTubeClient.defaultClient().getVideoWithIdentifier(videoId) { (video, error) -> Void in
            
            let url = video!.streamURLs[18] as! NSURL

            self.player = AVPlayer(URL: url)
            let playerLayer = AVPlayerLayer(player: self.player)
            playerLayer.frame = self.view.bounds
            self.view.layer.addSublayer(playerLayer)
            self.player.play()
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"applicationDidEnterBackground:", name: UIApplicationDidEnterBackgroundNotification, object: nil)
        
    }
    
    //for backround audio
    
    override func viewWillAppear(animated: Bool) {
        UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
        self.becomeFirstResponder()
    }

    
    override func viewWillDisappear(animated: Bool) {
        player.pause()
        UIApplication.sharedApplication().endReceivingRemoteControlEvents()
        self.resignFirstResponder()
    }
    
    override func remoteControlReceivedWithEvent(event: UIEvent?) {
        switch event!.subtype {
            
        case .RemoteControlTogglePlayPause:
            
            if player.rate == 0 {
                player.play()
            } else {
                player.pause()
            }
            break
        case .RemoteControlPlay:
            player.play()
            break
        case .RemoteControlPause:
            player.pause()
            break
        default:
            break
        }
    }

    func applicationDidEnterBackground(notification: NSNotification) {
        player.performSelector("play", withObject: nil, afterDelay: 0.01)
    }
    
    func play() {
        player.play()
    }

}
