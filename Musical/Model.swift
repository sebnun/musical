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
    
    
    static let color = UIColor.redColor()
    //some orange
    //static let color = UIColor(red:1.00, green:0.34, blue:0.13, alpha:1.0)
    //uiswitch gree
    //static let color = UIColor(red:0.29, green:0.85, blue:0.41, alpha:1.0)
}

