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
    
    //in case some error before is set
    var url = URL(string: "http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4")!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.black
        
        canDisplayBannerAds = true
        setNeedsStatusBarAppearanceUpdate()
        
        LNPopupBar.appearance().subtitleTextAttributes = [NSForegroundColorAttributeName: UIColor.lightGray]
        popupItem.leftBarButtonItems = [UIBarButtonItem(image: UIImage(named: "NowPlayingTransportControlPlay"), style: .plain, target: self, action: #selector(PlayerViewController.playPauseTapped(_:)))]
        popupItem.rightBarButtonItems = [UIBarButtonItem(image: UIImage(named: "repeatOff"), style: .plain, target: self, action: #selector(PlayerViewController.repeatTapped(_:)))]
        popupItem.rightBarButtonItems![0].tintColor = UIColor.gray
        
        setupForNewVideo()
    }
    
    func repeatTapped(_ sender: UIBarButtonItem) {
        
        if sender.tintColor == UIColor.gray {
            
            Musical.videoPlayerView.player.isLooping = true
            sender.tintColor = Musical.color
            
        } else {
            
            Musical.videoPlayerView.player.isLooping = false
            sender.tintColor = UIColor.gray
        }
    }
    
    func playPauseTapped (_ sender: UIBarButtonItem) {
        
        if Musical.videoPlayerView.player.isPlaying {
            
            Musical.pause()
            
        } else {
            
            Musical.play()
        }
    }
    
    func setupForNewVideo() {
        
        MBProgressHUD.showAdded(to: view, animated: true)
        
        popupItem.title = NSLocalizedString("Loading ...", comment: "")
        popupItem.subtitle = ""
        popupItem.progress = 0.0
        popupItem.leftBarButtonItems![0].isEnabled = false
        popupItem.rightBarButtonItems![0].isEnabled = false
        
        XCDYouTubeClient.default().getVideoWithIdentifier(videoId) { (video, error) -> Void in
            
            guard error == nil else {
                print("XCDYOUTUBE \(error)")
                
                let alert = UIAlertController(title: NSLocalizedString("OOPS", comment: ""), message: NSLocalizedString("An error occurred, try to load again.", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                
                self.popupItem.title = NSLocalizedString("An error occurred, try to load again.", comment: "")
                
                MBProgressHUD.hide(for: self.view, animated: true)
                
                return
            }
            
            //print(video!.streamURLs)
            
//            for (key, element) in video!.streamURLs {
//                print(key)
//            }
            
//            //can be nil appranetly
//            let url  = (video!.streamURLs[XCDYouTubeVideoQualityHTTPLiveStreaming] ??
//                video!.streamURLs[XCDYouTubeVideoQuality.HD720.rawValue] ??
//                video!.streamURLs[XCDYouTubeVideoQuality.medium360.rawValue] ??
//                video!.streamURLs[XCDYouTubeVideoQuality.small240.rawValue]) as? URL
            
            let url = video!.streamURLs.values.first!
            
            guard url != nil else {
                
                let alert = UIAlertController(title: NSLocalizedString("OOPS", comment: ""), message: NSLocalizedString("An error occurred, try to load again.", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                
                self.popupItem.title = NSLocalizedString("An error occurred, try to load again.", comment: "")
                
                MBProgressHUD.hide(for: self.view, animated: true)
                
                return
            }
            
            self.url = url

            self.resetPlayerAndSetURL()

            var thumbURL = URL(string: "http://schneeblog.com/wp-content/uploads/2013/08/blank.jpg")!
            if video!.largeThumbnailURL != nil {
                thumbURL = video!.largeThumbnailURL!
            } else if video!.mediumThumbnailURL != nil {
                thumbURL = video!.mediumThumbnailURL!
            }
            
            UIImageView().kf_setImage(with: thumbURL, placeholder: nil, options: .none, completionHandler: { (image, error, cacheType, imageURL) -> () in
                
//            UIImageView().kf_setImageWithURL(thumbURL, placeholderImage: nil, optionsInfo: .None, completionHandler: { (image, error, cacheType, imageURL) -> () in
//                
                if error != nil {
                    print("ERROR GETTING BIG THUM IMAGE \(imageURL)")
                }
                
                let songInfo = [
                    MPMediaItemPropertyTitle: self.videoTitle,
                    MPMediaItemPropertyArtist: self.videoChannelTitle,
                    MPMediaItemPropertyArtwork: MPMediaItemArtwork(image: image!),
                    MPMediaItemPropertyPlaybackDuration: CMTimeGetSeconds(Musical.videoPlayerView.player.player.currentItem == nil ? CMTimeMake(100, 60) : Musical.videoPlayerView.player.player.currentItem!.asset.duration) //can be nil when eeror occur in player
                ] as [String : Any]
                
                MPNowPlayingInfoCenter.default().nowPlayingInfo = songInfo
            })
        }
    }
    
    //to update status bar
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    //video delegate
    
    func videoPlayerViewIsReady(toPlayVideo videoPlayerView: VIMVideoPlayerView!) {
        
        Musical.play()
        
        MBProgressHUD.hide(for: view, animated: true)
        
        popupItem.leftBarButtonItems![0].isEnabled = true
        popupItem.rightBarButtonItems![0].isEnabled = true
        
        popupItem.title = videoTitle
        popupItem.subtitle = videoChannelTitle
        
    }
    
    
    func videoPlayerViewDidReachEnd(_ videoPlayerView: VIMVideoPlayerView!) {
        
        if Musical.videoPlayerView.player.isLooping {
            Musical.videoPlayerView.player.play()
        } else {
            
            //just keep user on video view with ads, they can tap to play again or dismissh video themselves
            Musical.popupContentController.popupItem.leftBarButtonItems![0].image = UIImage(named: "NowPlayingTransportControlPlay")
            popupItem.progress = 0
        }
    }
    
    //TODO: long videos sometimes gives errors
    func videoPlayerView(_ videoPlayerView: VIMVideoPlayerView!, didFailWithError error: NSError!) {
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
        
        if Musical.videoPlayerView != nil && Musical.videoPlayerView.player != nil && Musical.videoPlayerView.player.isPlaying {
            Musical.pause()
        }
        
        Musical.videoPlayerView = nil
        Musical.videoPlayerView = VIMVideoPlayerView(frame: view.bounds)
        Musical.videoPlayerView.delegate = self
        Musical.videoPlayerView.player.enableTimeUpdates()
        Musical.videoPlayerView.player.enableAirplay()
        Musical.videoPlayerView.player.isMuted = false
        Musical.videoPlayerView.player.isLooping = false
        Musical.videoPlayerView.setVideoFillMode(AVLayerVideoGravityResizeAspectFill)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(PlayerViewController.videoTapped(_:)))
        Musical.videoPlayerView.addGestureRecognizer(tapGesture)
        
        view.addSubview(Musical.videoPlayerView)
        
        //already have the url, not necessary
        //setupForNewVideo()
        
        Musical.videoPlayerView.player.reset()
        Musical.videoPlayerView.player.setURL(url) //should call play in isreadytoplay delegate?
    }
    
    func videoPlayerView(_ videoPlayerView: VIMVideoPlayerView!, timeDidChange cmTime: CMTime) {
        
        if Musical.videoPlayerView.player.player.currentItem != nil {
        
        let currentTime = CMTimeGetSeconds(Musical.videoPlayerView.player.player.currentTime())
        let videoDuration = CMTimeGetSeconds(Musical.videoPlayerView.player.player.currentItem!.duration)
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo![MPNowPlayingInfoPropertyElapsedPlaybackTime] = CMTimeGetSeconds(Musical.videoPlayerView.player.player.currentTime())
        
        popupItem.progress = Float(currentTime / videoDuration)
        }
    }
    
    ////////
    
    func videoTapped(_ gestureRecognizer: UIGestureRecognizer) {
        if Musical.videoPlayerView.player.isPlaying {
            
            Musical.pause()
            
        } else {
            
            Musical.play()
            
        }
    }
    
    //rotation
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        if Musical.videoPlayerView != nil {
            Musical.videoPlayerView.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        }
    }
    
    deinit {
        UIApplication.shared.endReceivingRemoteControlEvents()
    }
    
}
