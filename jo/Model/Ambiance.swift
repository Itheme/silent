//
//  Ambiance.swift
//  jo
//
//  Created by Danila Parkhomenko on 04.02.2020.
//  Copyright © 2020 Danila Parkhomenko. All rights reserved.
//

import UIKit

// area sound source
public class Ambiance: AbstractAudible {
    var inverted: Bool = false
    var inversionRadius0: Float = 1
    var inversionRadius1: Float = 1
    override init(details: [String:AnyObject]) {
        if let inversion = details["inversion"] as? [String:AnyObject] { // inversion radiuses
            self.inverted = true
            self.inversionRadius0 = inversion["r0"] as! Float
            self.inversionRadius1 = inversion["r1"] as! Float
        }
        super.init(details: details)
        
        self.audioPlayer.numberOfLoops = -1
        self.audioPlayer.prepareToPlay()
    }
}

extension Ambiance: StateCollector {
    func collectState() -> [String : AnyObject]? {
        return nil
    }
    func applyState(state: [String : AnyObject]) {
    }
}

extension Ambiance: Perspective {
    func applyPlayerPerspective(player: Player, run: Bool = false) {
        let fade = (run ?0:0.05)
        if self.inverted {
            let distance = dist(pos0: self.pos, pos1: player.pos)
            if distance > self.inversionRadius0 {
                if distance > self.inversionRadius1 {
                    self.audioPlayer.setVolume(1, fadeDuration: fade)
                } else {
                    self.audioPlayer.setVolume(volumeScale(distance: self.inversionRadius1 - distance), fadeDuration: fade)
                }
            } else {
                self.audioPlayer.setVolume(0, fadeDuration: fade)
            }
        } else {
            self.audioPlayer.setVolume(volumeScale(distance: dist(pos0: self.pos, pos1: player.pos)), fadeDuration: fade)
        }
        if (run) {
            self.audioPlayer.play()
        }
    }
}


