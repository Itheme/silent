//
//  Level.swift
//  jo
//
//  Created by Danila Parkhomenko on 04.02.2020.
//  Copyright © 2020 Danila Parkhomenko. All rights reserved.
//

import UIKit
import JavaScriptCore
import AVFoundation

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

class ScriptRepresentation: NSObject {
    let object: StateCollector
    let lastState: [String: AnyObject]
    let activeScript: String?
    init(id: String, stateCollector: StateCollector) {
        self.object = stateCollector
        self.lastState = stateCollector.collectState()!
        self.activeScript = lastState["script"] as? String
    }
}

class Scripting: NSObject {
    let machine = JSVirtualMachine()!
    let context: JSContext
    var collection: [String: ScriptRepresentation] = [:]
    private var loop: Int = 0
    init(details: [String:AnyObject]) {
        self.context = JSContext(virtualMachine: self.machine)
        self.context.evaluateScript("var console = {};")
        super.init()
        if let scripts = details["scripts"] as? [String: String] {
            scripts.forEach { [unowned self] (key: String, value: String) in
                self.context.evaluateScript("var \(key) = \(value);")
            }
        }
        let logClosure: @convention (block) (String, String, String, String) -> Void = { fmt, a, b, c in
            print(fmt, (a == "undefined") ?"":a, (b == "undefined") ?"":b, (c == "undefined") ?"":c)
        }
        self.context.objectForKeyedSubscript("console")?.setObject(logClosure, forKeyedSubscript: "log")
    }
    func representation(for id: String, object: StateCollector) -> JSValue {
        let representation = ScriptRepresentation(id: id, stateCollector: object)
        self.collection[id] = representation
        let serialized = try! JSONSerialization.data(withJSONObject: representation.lastState, options: [])
        if let scriptBody = String(data: serialized, encoding: .utf8) {
            self.context.evaluateScript("var \(id) = \(scriptBody);")
        }
        return self.context.objectForKeyedSubscript(id)
    }
    func updateRepresentation(for id: String, object: StateCollector) -> JSValue {
        let state = object.collectState()!
        let serialized = try! JSONSerialization.data(withJSONObject: state, options: [])
        if let script = String(data: serialized, encoding: .utf8) {
            self.context.evaluateScript("\(id) = \(script);")
        }
        return self.context.objectForKeyedSubscript(id)
    }
    
    func update(callback: (_ id: String) -> Void) {
        self.loop += 1
        if (self.loop % 10) == 0 {
            self.collection.forEach { (id: String, representation: ScriptRepresentation) in
                self.context.evaluateScript("\(representation)(\(id), \(self.loop))")
            }
        }
    }
}

public class Level: NSObject {
    private var details: [String:AnyObject]
    var player: Player
    var ambiances: [Ambiance] = []
    var audibles: [Audible] = []
    var running: Bool = false
    let engine: AVAudioEngine = AVAudioEngine()
    let scripting: Scripting
    init(details: [String:AnyObject]) {
        self.details = details
        self.scripting = Scripting(details: details)
        let playerDetails = (details["player"] as? [String:AnyObject]) ?? [:]
        self.player = Player(initialPoint: (playerDetails["pos"] as? CGPoint) ?? CGPoint(x: 0, y: 0), initialDirection: (playerDetails["direction"] as? CGFloat) ?? 0, scriptingEngine: self.scripting)
        super.init()
        if let ambianceDetails = details["ambiances"] as? [[String:AnyObject]] {
            self.ambiances = ambianceDetails.map {
                Ambiance(details: $0)
            }
        } else {
            self.ambiances = []
        }
        if let audibleDetails = details["audibles"] as? [[String:AnyObject]] {
            self.audibles = audibleDetails.map { [unowned self] in
                return Audible(details: $0, scriptingEngine: self.scripting)
            }
        } else {
            self.audibles = []
        }
    }
    func run() {
        self.ambiances.forEach { $0.applyPlayerPerspective(player: self.player, run: !self.running) }
        self.audibles.forEach { $0.applyPlayerPerspective(player: self.player, run: !self.running) }
        self.running = true
        
        self.scripting.update { (id: String) in
            //
        }
    }
    func playerMovement(speed: CGFloat, rotation: CGFloat) {
        self.player.set(speed: speed, direction: self.player.direction + (rotation / 10.0))
        if self.player.direction > CGFloat.pi {
            self.player.direction -= CGFloat.pi * 2.0
        }
        if self.player.direction < -CGFloat.pi {
            self.player.direction += CGFloat.pi * 2.0
        }
        let dx: CGFloat = cos(self.player.direction)*speed
        let dy: CGFloat = sin(self.player.direction)*speed
        self.player.pos.x += dx
        self.player.pos.x += dy
        self.player.updateScriptingContext(engine: self.scripting)

        self.run()
        //print("Speed: \(speed), Rotation: \(self.player.direction)")
    }
}
