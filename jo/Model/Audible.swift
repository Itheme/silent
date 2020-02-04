//
//  Audible.swift
//  jo
//
//  Created by Danila Parkhomenko on 04.02.2020.
//  Copyright © 2020 Danila Parkhomenko. All rights reserved.
//

import UIKit

// point sound source
public class Audible: AbstractAudible {
    override init(details: [String:AnyObject]) {
        super.init(details: details)
    
        // TEMPORARY:
        self.audioPlayer.numberOfLoops = -1
    }
}

extension Audible: StateCollector {
    func collectState() -> [String : AnyObject]? {
        let dict = ["pos": self.pos.string()]
        return dict as [String : AnyObject]
    }
    func applyState(state: [String : AnyObject]) {
        if let p = CGPoint(string: state["pos"] as? String) {
            self.pos = p
        }
    }
}

extension Audible: Perspective {
    func applyPlayerPerspective(player: Player, run: Bool = false) {
        let fade = run ?0:0.05
        let distance = dist(pos0: self.pos, pos1: player.pos)
        let dx = Float(player.pos.x - self.pos.x)//distance
        let dy = Float(player.pos.y - self.pos.y)//distance
        self.audioPlayer.setVolume(0.3*volumeScale(distance: distance), fadeDuration: fade)
        var angle = atan2f(dy, dx) - Float(player.direction)
        if angle > Float.pi {
            angle -= Float.pi * 2.0
        }
        if angle < -Float.pi {
            angle += Float.pi * 2.0
        }
        if angle > Float.pi / 2.0 {
            angle = Float.pi - angle
        } else {
            if angle < (-Float.pi / 2.0) {
                angle = -Float.pi - angle
            }
        }
        self.audioPlayer.pan = angle * 0.3
        //print("\(dist(pos0: self.pos, pos1: player.pos))")
        if (run) {
            self.audioPlayer.play()
        }
    }
}
