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
import iAd

class PlayerViewController: UIViewController {
    
    @IBOutlet weak var videoView: UIView!
    
    var videoTitle: String!
    var channelTitle: String!
    var videoId: String!
    var video: XCDYouTubeVideo!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //for backround audio
        try! AVAudioSession.sharedInstance().setActive(true)
        try! AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback) //withoption mixwithothers doesnt show nowplayinginfocenter
        UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
        
        popupItem.title = videoTitle
        popupItem.subtitle = channelTitle
        popupItem.progress = 0.5
        
        
        
        XCDYouTubeClient.defaultClient().getVideoWithIdentifier(videoId) { (video, error) -> Void in
            
            self.video = video
            
            let url  = (video!.streamURLs[XCDYouTubeVideoQualityHTTPLiveStreaming] ??
                video!.streamURLs[XCDYouTubeVideoQuality.HD720.rawValue] ??
                video!.streamURLs[XCDYouTubeVideoQuality.Medium360.rawValue] ??
                video!.streamURLs[XCDYouTubeVideoQuality.Small240.rawValue]) as! NSURL

            
            var items = [AVPlayerItem]()
            
            items.append(AVPlayerItem(URL: url))

            player = AVQueuePlayer(items: items)
            
            player.addObserver(self, forKeyPath: "status", options: ([]), context: nil)
            
        }
        
        canDisplayBannerAds = true
        //only once when the player is first displayed, like musi .. but musi has admob
        interstitialPresentationPolicy = .Automatic
        
        
    }
    

    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        
        if object as! AVQueuePlayer == player && keyPath as String! == "status" {
            
            //mayb thre a shorter way to doewnload thumb, alas ..
            let tempImageView = UIImageView()
            
            tempImageView.kf_setImageWithURL(video!.largeThumbnailURL ?? video!.mediumThumbnailURL!, placeholderImage: nil, optionsInfo: .None, completionHandler: { (image, error, cacheType, imageURL) -> () in
                
                let itemArtwork = MPMediaItemArtwork(image: tempImageView.image!)
                
                let songInfo: Dictionary = [
                    MPMediaItemPropertyTitle: self.videoTitle,
                    MPMediaItemPropertyArtist: self.channelTitle,
                    MPMediaItemPropertyArtwork: itemArtwork,
                    MPMediaItemPropertyPlaybackDuration : CMTimeGetSeconds(player.currentItem!.asset.duration)
                ]
                
                MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = songInfo
                
                player.play()
            })


        }
    }

    
    deinit {
        UIApplication.sharedApplication().endReceivingRemoteControlEvents()
        self.removeObserver(self, forKeyPath: "status")
    }

    
    override func viewDidAppear(animated: Bool) {
        if popupPresentationState == .Open {
            requestInterstitialAdPresentation()
        }
    }
}
