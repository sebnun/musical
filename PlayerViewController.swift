//
//  PlayerViewController.swift
//  Musical
//
//  Created by Sebastian on 10/24/15.
//  Copyright © 2015 Sebastian. All rights reserved.
//

import UIKit
import LNPopupController

class PlayerViewController: UIViewController {
    
    var videoTitle: String!
    var channelTitle: String!
    var videoId: String!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        popupItem.title = videoTitle
        popupItem.subtitle = channelTitle
        
        //get thumb using api, directly using http://img./youtubeid/..  for kingfisher handling or with hcyoutubeparser?

    }


}
