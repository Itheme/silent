//
//  Player.swift
//  jo
//
//  Created by Danila Parkhomenko on 04.02.2020.
//  Copyright © 2020 Danila Parkhomenko. All rights reserved.
//

import UIKit
import AVKit

public class Player: NSObject {
    var pos: CGPoint = CGPoint.zero
    var direction: CGFloat = 0 // angle in radians
    var speed: CGFloat = 0
    var audioPlayer: AVAudioPlayer
    init(initialPoint: CGPoint, initialDirection: CGFloat, scriptingEngine: Scripting) {
        let url = Bundle.main.url(forResource: "steps01", withExtension: "mp3")!
        self.audioPlayer = try! AVAudioPlayer(contentsOf: url)
        super.init()
        self.pos = initialPoint
        self.direction = initialDirection
        scriptingEngine.createRepresentation(for: "player", params: nil, object: self)
        self.audioPlayer.prepareToPlay()
        self.audioPlayer.volume = 0.2
        self.audioPlayer.numberOfLoops = -1
    }
    func set(speed: CGFloat, direction: CGFloat) {
        self.speed = speed
        let d = direction
        if d > CGFloat.pi {
            self.direction = d - CGFloat.pi * 2.0
        } else {
            if d < -CGFloat.pi {
                self.direction = d + CGFloat.pi * 2.0
            } else {
                self.direction = d
            }
        }
        if abs(speed) > 0.0 {
            if !self.audioPlayer.isPlaying {
                self.audioPlayer.play()
            }
//            self.audioPlayer.enableRate = true
//            self.audioPlayer.rate = 0.8 + Float(abs(speed)*1.5)
        } else {
            self.audioPlayer.stop()
        }

    }
    func updateScriptingContext(engine: Scripting) {
        engine.updateRepresentation(for: "player", object: self)
    }

}

extension Player: StateCollector {
    public func collectState() -> [String : AnyObject]? {
        let dict: [String : Any] = ["pos": ["x": self.pos.x, "y": self.pos.y], "direction": self.direction, "speed": self.speed]
        return dict as [String : AnyObject]
    }
    public func applyState(state: [String : AnyObject]) {
        if let posString = state["pos"] as? String {
            guard let p = CGPoint(string: posString) else { return }
            self.pos = p
        } else {
            guard let posDict = state["pos"] as? [String: CGFloat] else { return }
            self.pos = CGPoint(x: posDict["x"]!, y: posDict["y"]!)
        }
    }
}
