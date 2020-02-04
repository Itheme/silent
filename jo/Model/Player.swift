//
//  Player.swift
//  jo
//
//  Created by Danila Parkhomenko on 04.02.2020.
//  Copyright © 2020 Danila Parkhomenko. All rights reserved.
//

import UIKit
import AVKit
import JavaScriptCore

public class Player: NSObject {
    var pos: CGPoint
    var direction: CGFloat // angle in radians
    var speed: CGFloat = 0
    var scriptRepresentation: JSValue
    var posScriptRepresentation: JSValue
    var audioPlayer: AVAudioPlayer
    init(initialPoint: CGPoint, initialDirection: CGFloat, scriptRepresentation: JSValue) {
        self.pos = initialPoint
        self.direction = initialDirection
        self.scriptRepresentation = scriptRepresentation
        self.posScriptRepresentation = self.scriptRepresentation.objectForKeyedSubscript("pos")
        let url = Bundle.main.url(forResource: "steps01", withExtension: "mp3")!
        self.audioPlayer = try! AVAudioPlayer(contentsOf: url)
        self.audioPlayer.prepareToPlay()
        self.audioPlayer.numberOfLoops = -1
    }
    func set(speed: CGFloat, direction: CGFloat) {
        self.direction = direction
        self.speed = speed
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
    func updateJSContext() {
        self.posScriptRepresentation.setValue(pos.x, forProperty: "x")
        self.posScriptRepresentation.setValue(pos.y, forProperty: "y")
        self.scriptRepresentation.setValue(direction, forProperty: "direction")
    }

}
