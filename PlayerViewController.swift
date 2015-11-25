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
    
    @IBOutlet weak var artImageView: UIImageView!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var timePassedLabel: UILabel!
    @IBOutlet weak var timeRemainingLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var slider: UISlider!
    
    var videoTitle: String!
    var videoId: String!
    var video: XCDYouTubeVideo!
    
    
    @IBAction func repeatTapped(sender: UIButton) {
        print("dsf")
    }
    
    
    @IBAction func playTapped(sender: UIButton) {
        
    }
    
    
    @IBAction func shareTapped(sender: UIButton) {
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        popupItem.title = "Loading ..."
        popupItem.progress = 0.0
        
        XCDYouTubeClient.defaultClient().getVideoWithIdentifier(videoId) { (video, error) -> Void in
            
            if error == nil {
                
                self.video = video
                
                let url  = (video!.streamURLs[XCDYouTubeVideoQualityHTTPLiveStreaming] ??
                    video!.streamURLs[XCDYouTubeVideoQuality.HD720.rawValue] ??
                    video!.streamURLs[XCDYouTubeVideoQuality.Medium360.rawValue] ??
                    video!.streamURLs[XCDYouTubeVideoQuality.Small240.rawValue]) as! NSURL
                
                player = AVPlayer(URL: url)
                
                //KVO has to be registered/unregistered on the main queue
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    player.currentItem!.addObserver(self, forKeyPath: "status", options: ([]), context: nil)
                })
                
                
                //mayb thre a shorter way to doewnload thumb, alas ..
                UIImageView().kf_setImageWithURL(video!.largeThumbnailURL ?? video!.mediumThumbnailURL!, placeholderImage: nil, optionsInfo: .None, completionHandler: { (image, error, cacheType, imageURL) -> () in
                    
                    if error == nil {
                        
                        let squareImage = self.imageSquareByCroppingWideImage(image!)
                        
                        let itemArtwork = MPMediaItemArtwork(image: squareImage)
                        
                        let songInfo: Dictionary = [
                            MPMediaItemPropertyTitle: self.videoTitle,
                            MPMediaItemPropertyArtwork: itemArtwork,
                            MPMediaItemPropertyPlaybackDuration : CMTimeGetSeconds(player.currentItem!.asset.duration)
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
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "playerReachedTheEnd", name: AVPlayerItemDidPlayToEndTimeNotification, object: player.currentItem)
        
        //if its iohone 4 dont diplsy banner ads, can obstruct player buton
        canDisplayBannerAds = true
        //only once when the player is first displayed, like musi .. but musi has admob
        interstitialPresentationPolicy = .Automatic
        
        //to update status bar
        setNeedsStatusBarAppearanceUpdate()
        
        //slider thumb
        let rect = CGRectMake(0,0,3,14)
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(3,14), false, 0)
        UIColor.blueColor().setFill()
        UIRectFill(rect)
        let thumb: UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        UISlider.appearance().setThumbImage(thumb, forState: .Normal)
        
        //for backround audio
        try! AVAudioSession.sharedInstance().setActive(true)
        try! AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback) //withoption mixwithothers doesnt show nowplayinginfocenter
        UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
    }
    
    
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        
        if keyPath as String! == "status" {
            
            if player.currentItem!.status == .ReadyToPlay {
                //put and end to "loading" meesage, right after can actually play
                popupItem.title = videoTitle
                player.play()
                
            } else {
                print("the player failed for some reason")
            }
        }
    }
    
    
    deinit {
        UIApplication.sharedApplication().endReceivingRemoteControlEvents()
        player.currentItem!.removeObserver(self, forKeyPath: "status")
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    
    override func viewDidAppear(animated: Bool) {
        if popupPresentationState == .Open {
            requestInterstitialAdPresentation()
        }
    }
    
    //to update status bar
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    func imageSquareByCroppingWideImage(image : UIImage) -> UIImage {
        
        //assumes images from youtube which have more width than height
        
        let size = CGSize(width: CGImageGetHeight(image.CGImage), height: CGImageGetHeight(image.CGImage))
        
        let refWidth : CGFloat = CGFloat(CGImageGetWidth(image.CGImage))
        let refHeight : CGFloat = CGFloat(CGImageGetHeight(image.CGImage))
        
        let x = (refWidth - size.width) / 2
        let y = (refHeight - size.height) / 2
        
        let cropRect = CGRectMake(x, y, size.height, size.width)
        let imageRef = CGImageCreateWithImageInRect(image.CGImage, cropRect)
        
        return UIImage(CGImage: imageRef!, scale: 0, orientation: image.imageOrientation)
    }
    
}
