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
    
    var url: NSURL!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.blackColor()
        
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
        
        MBProgressHUD.showHUDAddedTo(view, animated: true)
        
        popupItem.title = NSLocalizedString("Loading ...", comment: "")
        popupItem.subtitle = ""
        popupItem.progress = 0.0
        popupItem.leftBarButtonItems![0].enabled = false
        popupItem.rightBarButtonItems![0].enabled = false
        
        XCDYouTubeClient.defaultClient().getVideoWithIdentifier(videoId) { (video, error) -> Void in
            
            if error != nil {
                print("XCDYOUTUBE \(error)")
            }
            
            //can be nil appranetly
            let url  = (video!.streamURLs[XCDYouTubeVideoQualityHTTPLiveStreaming] ??
                video!.streamURLs[XCDYouTubeVideoQuality.HD720.rawValue] ??
                video!.streamURLs[XCDYouTubeVideoQuality.Medium360.rawValue] ??
                video!.streamURLs[XCDYouTubeVideoQuality.Small240.rawValue]) as? NSURL
            
            guard url != nil else {
                
                let alert = UIAlertController(title: NSLocalizedString("OOPS", comment: ""), message: NSLocalizedString("An error occurred, try to load again.", comment: ""), preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
                
                self.popupItem.title = NSLocalizedString("An error occurred, try to load again.", comment: "")
                
                MBProgressHUD.hideHUDForView(self.view, animated: true)
                
                return
            }
            
            self.url = url!

            self.resetPlayerAndSetURL()
            
            var thumbURL = NSURL(string: "http://schneeblog.com/wp-content/uploads/2013/08/blank.jpg")!
            if video!.largeThumbnailURL != nil {
                thumbURL = video!.largeThumbnailURL!
            } else if video!.mediumThumbnailURL != nil {
                thumbURL = video!.mediumThumbnailURL!
            }
            
            UIImageView().kf_setImageWithURL(thumbURL, placeholderImage: nil, optionsInfo: .None, completionHandler: { (image, error, cacheType, imageURL) -> () in
                
                if error != nil {
                    print("ERROR GETTING BIG THUM IMAGE \(imageURL)")
                }
                
                let songInfo = [
                    MPMediaItemPropertyTitle: self.videoTitle,
                    MPMediaItemPropertyArtist: self.videoChannelTitle,
                    MPMediaItemPropertyArtwork: MPMediaItemArtwork(image: image!),
                    MPMediaItemPropertyPlaybackDuration: CMTimeGetSeconds(Musical.videoPlayerView.player.player.currentItem == nil ? CMTimeMake(100, 60) : Musical.videoPlayerView.player.player.currentItem!.asset.duration) //can be nil when eeror occur in player
                ]
                
                MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = songInfo
            })
        }
    }
    
    //to update status bar
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    //video delegate
    
    func videoPlayerViewIsReadyToPlayVideo(videoPlayerView: VIMVideoPlayerView!) {
        
        Musical.play()
        
        MBProgressHUD.hideHUDForView(view, animated: true)
        
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
    
    //TODO: long videos sometimes gives errors
    func videoPlayerView(videoPlayerView: VIMVideoPlayerView!, didFailWithError error: NSError!) {
        //print(" DID FAIL WIRKTH ERRO \(error)") // error prints itself
        
//        let alert = UIAlertController(title: NSLocalizedString("OOPS", comment: ""), message: NSLocalizedString("An error occurred, try to load again.", comment: ""), preferredStyle: UIAlertControllerStyle.Alert)
//        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
//        UIApplication.sharedApplication().keyWindow?.rootViewController?.presentViewController(alert, animated: true, completion: nil)
//        
//        self.popupItem.title = NSLocalizedString("An error occurred, try to load again.", comment: "")

        //MBProgressHUD.hideHUDForView(view, animated: true)
        
       resetPlayerAndSetURL()
        
        //if the player is stuck in spinning indicator, they can swipe down and choose other video and it works ok
        
//        let player = AVPlayer(URL: url)
//        let playerLayer = AVPlayerLayer(player: player)
//        view.layer.addSublayer(playerLayer)
//        playerLayer.frame = view.bounds
//        player.play()
    }
    
    func resetPlayerAndSetURL() {
        
        print("reseting player")
        
        if Musical.videoPlayerView != nil && Musical.videoPlayerView.player != nil && Musical.videoPlayerView.player.playing {
            Musical.pause()
        }
        
        Musical.videoPlayerView = nil
        Musical.videoPlayerView = VIMVideoPlayerView(frame: view.bounds)
        Musical.videoPlayerView.delegate = self
        Musical.videoPlayerView.player.enableTimeUpdates()
        Musical.videoPlayerView.player.enableAirplay()
        Musical.videoPlayerView.player.muted = false
        Musical.videoPlayerView.player.looping = false
        Musical.videoPlayerView.setVideoFillMode(AVLayerVideoGravityResizeAspectFill)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: "videoTapped:")
        Musical.videoPlayerView.addGestureRecognizer(tapGesture)
        
        view.addSubview(Musical.videoPlayerView)
        
        //already have the url, not necessary
        //setupForNewVideo()
        
        Musical.videoPlayerView.player.reset()
        Musical.videoPlayerView.player.setURL(url) //should call play in isreadytoplay delegate?
    }
    
    func videoPlayerView(videoPlayerView: VIMVideoPlayerView!, timeDidChange cmTime: CMTime) {
        
        if Musical.videoPlayerView.player.player.currentItem != nil {
        
        let currentTime = CMTimeGetSeconds(Musical.videoPlayerView.player.player.currentTime())
        let videoDuration = CMTimeGetSeconds(Musical.videoPlayerView.player.player.currentItem!.duration)
        
        MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo![MPNowPlayingInfoPropertyElapsedPlaybackTime] = CMTimeGetSeconds(Musical.videoPlayerView.player.player.currentTime())
        
        popupItem.progress = Float(currentTime / videoDuration)
        }
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
