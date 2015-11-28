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

class PlayerViewController: UIViewController, VIMVideoPlayerViewDelegate {
    
    var videoTitle: String!
    var videoId: String!
    var videoChannelTitle: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Musical.videoPlayerView = VIMVideoPlayerView(frame: view.bounds)
        Musical.videoPlayerView.delegate = self
        Musical.videoPlayerView.player.enableTimeUpdates()
        Musical.videoPlayerView.player.enableAirplay()
        Musical.videoPlayerView.player.muted = false
        Musical.videoPlayerView.player.looping = false
        Musical.videoPlayerView.setVideoFillMode(AVLayerVideoGravityResizeAspectFill)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: "videoTapped:")
        Musical.videoPlayerView.addGestureRecognizer(tapGesture)
        
        view.backgroundColor = Musical.color
        view.addSubview(Musical.videoPlayerView)
        
        canDisplayBannerAds = true
        setNeedsStatusBarAppearanceUpdate()
        UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
        
        LNPopupBar.appearance().subtitleTextAttributes = [NSForegroundColorAttributeName: UIColor.lightGrayColor()]
        popupItem.leftBarButtonItems = [UIBarButtonItem(image: UIImage(named: "NowPlayingTransportControlPlay"), style: .Plain, target: self, action: "playPauseTapped:")]
        popupItem.rightBarButtonItems = [UIBarButtonItem(image: UIImage(named: "repeatOff"), style: .Plain, target: self, action: "repeatTapped:")]
        popupItem.rightBarButtonItems![0].tintColor = UIColor.grayColor()
        
        setupForNewVideo()
    }
    
    func repeatTapped(sender: UIBarButtonItem) {
        
        if sender.tintColor == UIColor.grayColor() {
            
            Musical.videoPlayerView.player.looping = true
            sender.tintColor = Musical.color
            
        } else {
            
            Musical.videoPlayerView.player.looping = false
            sender.tintColor = UIColor.grayColor()
            
        }
    }
    
    func playPauseTapped (sender: UIBarButtonItem) {
        
        if Musical.videoPlayerView.player.playing {
            
            Musical.pause()
            
        } else {
            
            Musical.play()
        }
    }
    
    func setupForNewVideo() {
        
        popupItem.title = "Loading ..."
        popupItem.subtitle = ""
        popupItem.progress = 0.0
        popupItem.leftBarButtonItems![0].enabled = false
        popupItem.rightBarButtonItems![0].enabled = false
    
        
        XCDYouTubeClient.defaultClient().getVideoWithIdentifier(videoId) { (video, error) -> Void in
            
            if error == nil {
                
                let url  = (video!.streamURLs[XCDYouTubeVideoQualityHTTPLiveStreaming] ??
                    video!.streamURLs[XCDYouTubeVideoQuality.HD720.rawValue] ??
                    video!.streamURLs[XCDYouTubeVideoQuality.Medium360.rawValue] ??
                    video!.streamURLs[XCDYouTubeVideoQuality.Small240.rawValue]) as! NSURL
                
                Musical.videoPlayerView.player.setURL(url)
                
                UIImageView().kf_setImageWithURL(video!.largeThumbnailURL ?? video!.mediumThumbnailURL!, placeholderImage: nil, optionsInfo: .None, completionHandler: { (image, error, cacheType, imageURL) -> () in
                    
                    if error == nil {
                        
                        let songInfo: Dictionary = [
                            MPMediaItemPropertyTitle: self.videoTitle,
                            MPMediaItemPropertyArtist: self.videoChannelTitle,
                            MPMediaItemPropertyArtwork: MPMediaItemArtwork(image: image!),
                            MPMediaItemPropertyPlaybackDuration: CMTimeGetSeconds(Musical.videoPlayerView.player.player.currentItem!.asset.duration)
                        ]
                        
                        MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = songInfo
                        
                    } else {
                        print("error gettign big thumb")
                    }
                })
                
                
            } else {
                print("error xcdyoutube getting video")
            }
        }
        
        
    }
    
    //to update status bar
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    //video delegate
    
    func videoPlayerViewIsReadyToPlayVideo(videoPlayerView: VIMVideoPlayerView!) {
        
        Musical.play()
        
        popupItem.leftBarButtonItems![0].enabled = true
        popupItem.rightBarButtonItems![0].enabled = true
        
        popupItem.title = videoTitle
        popupItem.subtitle = videoChannelTitle
        
    }
    
    
    func videoPlayerViewDidReachEnd(videoPlayerView: VIMVideoPlayerView!) {
        
        if Musical.videoPlayerView.player.looping {
            Musical.videoPlayerView.player.play()
        } else {
            
            //just keep user on video view with ads, they can tap to play again or dismissh video themselves
            Musical.popupContentController.popupItem.leftBarButtonItems![0].image = UIImage(named: "NowPlayingTransportControlPlay")
            popupItem.progress = 0
        }
    }
    
    func videoPlayerView(videoPlayerView: VIMVideoPlayerView!, didFailWithError error: NSError!) {
        print(" DID FAIL WIRKTH ERRO \(error)")
    }
    
    func videoPlayerView(videoPlayerView: VIMVideoPlayerView!, timeDidChange cmTime: CMTime) {
        
        let currentTime = CMTimeGetSeconds(Musical.videoPlayerView.player.player.currentTime())
        let videoDuration = CMTimeGetSeconds(Musical.videoPlayerView.player.player.currentItem!.duration)
        
        MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo![MPNowPlayingInfoPropertyElapsedPlaybackTime] = CMTimeGetSeconds(Musical.videoPlayerView.player.player.currentTime())
        
        popupItem.progress = Float(currentTime / videoDuration)
    }
    
    ////////
    
    func videoTapped(gestureRecognizer: UIGestureRecognizer) {
        if Musical.videoPlayerView.player.playing {
            
            Musical.pause()
            
        } else {
            
            Musical.play()
            
        }
    }
    
    //rotation
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        if Musical.videoPlayerView != nil {
            Musical.videoPlayerView.frame = CGRectMake(0, 0, size.width, size.height)
        }
    }
    
    
    
    
    deinit {
        UIApplication.sharedApplication().endReceivingRemoteControlEvents()
    }
    
}
