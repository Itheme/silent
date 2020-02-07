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
    override init(details: [String:AnyObject], audioManager: AudioManager) {
        if let inversion = details["inversion"] as? [String:AnyObject] { // inversion radiuses
            self.inverted = true
            self.inversionRadius0 = inversion["r0"] as! Float
            self.inversionRadius1 = inversion["r1"] as! Float
        }
        super.init(details: details, audioManager: audioManager)
        
        self.audioPlayer.isLooping = true
        self.audioPlayer.prepare()
    }
}

extension Ambiance: StateCollector {
    public func collectState() -> [String : AnyObject]? {
        return nil
    }
    public func applyState(state: [String : AnyObject]) {
    }
}

extension Ambiance: Perspective {
    func applyPlayerPerspective(player: Player, run: Bool = false) {
        //let fade = (run ?0:0.05)
        if self.inverted {
            let distance = dist(pos0: self.pos, pos1: player.pos)
            if distance > self.inversionRadius0 {
                if distance > self.inversionRadius1 {
                    self.audioPlayer.volume = 1// setVolume(1, fadeDuration: fade)
                } else {
                    self.audioPlayer.volume = Double(volumeScale(distance: self.inversionRadius1 - distance))//, fadeDuration: fade)
                }
            } else {
                self.audioPlayer.volume = 0//setVolume(0, fadeDuration: fade)
            }
        } else {
            self.audioPlayer.volume = Double(volumeScale(distance: dist(pos0: self.pos, pos1: player.pos)))//, fadeDuration: fade)
        }
        if (run) {
            self.audioPlayer.play()
        }
    }
}


