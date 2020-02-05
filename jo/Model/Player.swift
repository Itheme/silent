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
    var scriptRepresentation: AnyObject? = nil
    var audioPlayer: AVAudioPlayer
    init(initialPoint: CGPoint, initialDirection: CGFloat, scriptingEngine: Scripting) {
        let url = Bundle.main.url(forResource: "steps01", withExtension: "mp3")!
        self.audioPlayer = try! AVAudioPlayer(contentsOf: url)
        super.init()
        self.pos = initialPoint
        self.direction = initialDirection
        self.scriptRepresentation = scriptingEngine.representation(for: "player", object: self)
        self.audioPlayer.prepareToPlay()
        self.audioPlayer.numberOfLoops = -1
    }
    func set(speed: CGFloat, direction: CGFloat) {
        self.speed = speed
        if direction > CGFloat.pi {
            self.direction = direction - CGFloat.pi * 2.0
        } else {
            if direction < -CGFloat.pi {
                self.direction = direction + CGFloat.pi * 2.0
            } else {
                self.direction = direction
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
        self.scriptRepresentation = engine.updateRepresentation(for: "player", object: self)
    }

}

extension Player: StateCollector {
    public func collectState() -> [String : AnyObject]? {
        let dict: [String : Any] = ["pos": self.pos.string(), "direction": self.direction, "speed": self.speed]
        return dict as [String : AnyObject]
    }
    public func applyState(state: [String : AnyObject]) {
        if let p = CGPoint(string: state["pos"] as? String) {
            self.pos = p
        }
    }
}
