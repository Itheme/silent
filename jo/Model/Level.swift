//
//  Level.swift
//  jo
//
//  Created by Danila Parkhomenko on 04.02.2020.
//  Copyright © 2020 Danila Parkhomenko. All rights reserved.
//

import UIKit
import JavaScriptCore

protocol StateCollector {
    func collectState() -> [String:AnyObject]?
    func applyState(state: [String:AnyObject]) -> Void
}

protocol Perspective {
    func applyPlayerPerspective(player: Player, run: Bool) -> Void
}

func volumeScale(distance: Float) -> Float {
    return 1.0/exp(distance*0.1) // temporary
}

func dist(pos0: CGPoint, pos1: CGPoint) -> Float {
    let dx = pos0.x - pos1.x
    let dy = pos0.y - pos1.y
    return sqrtf(Float(dx*dx + dy*dy))
}

extension CGPoint {
    func string() -> String { return "\(self.x);\(self.y)" }
    init?(string: String?) {
        guard let coordinatesString = string else {
            return nil
        }
        let coords = coordinatesString.split(separator: ";")
        guard coords.count > 1 else {
            return nil
        }
        self.init()
        self.x = CGFloat((coords[0] as NSString).floatValue)
        self.y = CGFloat((coords[1] as NSString).floatValue)
    }
}

// area sound source
class Ambiance: AbstractAudible {
    var inverted: Bool
    override init(details: [String:AnyObject]) {
        self.inverted = (details["inverted"] as? Bool) ?? false
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
        self.audioPlayer.setVolume(volumeScale(distance: dist(pos0: self.pos, pos1: player.pos)), fadeDuration: 0.05)
        if (run) {
            self.audioPlayer.play()
        }
    }
}

// point sound source
class Audible: AbstractAudible {
    override init(details: [String:AnyObject]) {
        super.init(details: details)
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
        self.audioPlayer.setVolume(volumeScale(distance: dist(pos0: self.pos, pos1: player.pos)), fadeDuration: 0.05)
        if (run) {
            self.audioPlayer.play()
        }
    }
}

public class Level: NSObject {
    private var details: [String:AnyObject]
    var player: Player
    var ambiances: [Ambiance]
    var audibles: [Audible]
    var running: Bool = false
    let machine = JSVirtualMachine()!
    let context: JSContext
    let contextObjectPlayer: JSValue
    init(details: [String:AnyObject]) {
        self.details = details
        self.context = JSContext(virtualMachine: self.machine)
        self.context.evaluateScript("var console = {}; var player = {'pos': {}};")
        self.contextObjectPlayer = self.context.objectForKeyedSubscript("player")
        let logClosure: @convention (block) (String, String, String, String) -> Void = { fmt, a, b, c in
            print(fmt, a, b, c)
        }
        self.context.objectForKeyedSubscript("console")?.setObject(logClosure, forKeyedSubscript: "log")

        //self.context.evaluateScript("console.log('stuff')")
        self.context.setObject(22, forKeyedSubscript: "number" as NSString)
        self.context.evaluateScript("console.log('hi from js')")
        self.context.evaluateScript("number = number + 20")
        print("\(self.context.objectForKeyedSubscript("number"))")
        let playerDetails = (details["player"] as? [String:AnyObject]) ?? [:]
        self.player = Player(initialPoint: (playerDetails["pos"] as? CGPoint) ?? CGPoint(x: 0, y: 0), initialDirection: (playerDetails["direction"] as? CGFloat) ?? 0, scriptRepresentation: self.contextObjectPlayer)
        self.player.updateJSContext()
        //self.context.evaluateScript("player.pos.x = 100")
        print("\(self.contextObjectPlayer.objectForKeyedSubscript("pos.x")!)")
        if let ambianceDetails = details["ambiances"] as? [[String:AnyObject]] {
            self.ambiances = ambianceDetails.map {
                Ambiance(details: $0)
            }
        } else {
            self.ambiances = []
        }
        if let audibleDetails = details["audibles"] as? [[String:AnyObject]] {
            self.audibles = audibleDetails.map {
                Audible(details: $0)
            }
        } else {
            self.audibles = []
        }
    }
    func run() {
        self.ambiances.forEach { $0.applyPlayerPerspective(player: self.player, run: !self.running) }
        self.audibles.forEach { $0.applyPlayerPerspective(player: self.player, run: !self.running) }
        self.running = true
    }
    func playerMovement(speed: CGFloat, rotation: CGFloat) {
        self.player.direction += rotation / 10.0
        if self.player.direction > CGFloat.pi {
            self.player.direction -= CGFloat.pi
        }
        if self.player.direction < -CGFloat.pi {
            self.player.direction += CGFloat.pi
        }
        let dx: CGFloat = cos(self.player.direction)*speed
        let dy: CGFloat = sin(self.player.direction)*speed
        self.player.pos.x += dx
        self.player.pos.x += dy

        self.run()
        print("Speed: \(speed), Rotation: \(self.player.direction)")
    }
}
