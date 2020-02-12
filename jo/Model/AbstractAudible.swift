//
//  AbstractAudible.swift
//  jo
//
//  Created by Danila Parkhomenko on 04.02.2020.
//  Copyright © 2020 Danila Parkhomenko. All rights reserved.
//

import UIKit
import AudioKit

open class AbstractAudible: NSObject {
    var audioPlayer: AKPlayer
    var pos: CGPoint
    init(details: [String: AnyObject], audioManager: AudioManager) {
        let urlString = details["url"] as! String
        if let posString = details["pos"] as? String {
            self.pos = CGPoint(string: posString)!
        } else {
            let posDict = details["pos"] as! [String:CGFloat]
            self.pos = CGPoint(x: posDict["x"]!, y: posDict["y"]!)
        }
        self.audioPlayer = audioManager.addPlayer(fileName: urlString)
    }
    func stop() {
        self.audioPlayer.stop()
    }
}
