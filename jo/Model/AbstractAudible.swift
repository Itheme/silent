//
//  AbstractAudible.swift
//  jo
//
//  Created by Danila Parkhomenko on 04.02.2020.
//  Copyright © 2020 Danila Parkhomenko. All rights reserved.
//

import UIKit
import AVKit

open class AbstractAudible: NSObject {
    var audioPlayer: AVAudioPlayer
    var pos: CGPoint
    init(details: [String: AnyObject]) {
        let urlString = details["url"] as! String
        let url = Bundle.main.url(forResource: urlString, withExtension: "mp3")!
        self.pos = CGPoint(string: details["pos"] as? String)!
        self.audioPlayer = try! AVAudioPlayer(contentsOf: url)
    }
}
