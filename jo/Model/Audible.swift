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
    let id: String
    var scriptName: String
    init(details: [String:AnyObject], scriptingEngine: Scripting) {
        self.id = details["id"] as! String
        self.scriptName = details["script"] as! String
        super.init(details: details)
        scriptingEngine.createRepresentation(for: self.id, params: details["params"] as? [String : AnyObject], object: self)

        // TEMPORARY:
        self.audioPlayer.numberOfLoops = -1
    }
    func kill() {
        self.audioPlayer.stop()
    }
}

extension Audible: StateCollector {
    public func collectState() -> [String : AnyObject]? {
        let dict: [String : AnyObject] = ["pos": ["x": self.pos.x, "y": self.pos.y] as AnyObject, "script": self.scriptName as AnyObject]
        return dict as [String : AnyObject]
    }
    public func applyState(state: [String : AnyObject]) {
        if let posString = state["pos"] as? String {
            self.pos = CGPoint(string: posString)!
        } else {
            if let posDict = state["pos"] as? [String:CGFloat] {
                self.pos = CGPoint(x: posDict["x"]!, y: posDict["y"]!)
            }
        }
        if let s = state["script"] as? String {
            self.scriptName = s
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
