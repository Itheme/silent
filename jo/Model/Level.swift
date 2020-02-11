//
//  Level.swift
//  jo
//
//  Created by Danila Parkhomenko on 04.02.2020.
//  Copyright © 2020 Danila Parkhomenko. All rights reserved.
//

import UIKit
import AVFoundation
import AudioKit

let ActionProximity: CGFloat = 3.0

public protocol StateCollector {
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

class AudioManager: NSObject {
    var audioFiles: [String: AKAudioFile] = [:]
    let mixer: AKMixer = AKMixer()
    init(details: [String: AnyObject]) {
        super.init()
        if let ambianceDetails = details["ambiances"] as? [[String:AnyObject]] {
            for ambiance in ambianceDetails {
                guard let fileName = ambiance["url"] as? String else { continue }
                let ext = ambiance["ext"] as? String ?? "mp3"
                if audioFiles[fileName] == nil {
                    audioFiles[fileName] = try! AKAudioFile(forReading: Bundle.main.url(forResource: fileName, withExtension: ext)!)
                }
            }
        }
        if let audibleDetails = details["audibles"] as? [[String:AnyObject]] {
            for audible in audibleDetails {
                guard let fileName = audible["url"] as? String else { continue }
                let ext = audible["ext"] as? String ?? "mp3"
                if audioFiles[fileName] == nil {
                    audioFiles[fileName] = try! AKAudioFile(forReading: Bundle.main.url(forResource: fileName, withExtension: ext)!)
                }
            }
        }
        AudioKit.output = self.mixer
    }
    func addPlayer(fileName: String) -> AKPlayer {
        let player = AKPlayer(audioFile: self.audioFiles[fileName]!)
        player.isLooping = true
        self.mixer.connect(input: player)
        return player
    }
}

public class Level: NSObject {
    private var details: [String:AnyObject]
    var player: Player
    var ambiances: [Ambiance] = []
    var audibles: [Audible] = []
    var running: Bool = false
    let audioManager: AudioManager;
    let engine: AVAudioEngine = AVAudioEngine()
    let scripting: Scripting
    var actionAudioPlayer: AVAudioPlayer = try! AVAudioPlayer(contentsOf: Bundle.main.url(forResource: "action02", withExtension: "mp3")!)
    init(details: [String:AnyObject]) {
        self.details = details
        self.scripting = Scripting(details: details)
        let playerDetails = (details["player"] as? [String:AnyObject]) ?? [:]
        self.player = Player(initialPoint: (playerDetails["pos"] as? CGPoint) ?? CGPoint(x: 0, y: 0), initialDirection: (playerDetails["direction"] as? CGFloat) ?? 0, scriptingEngine: self.scripting)
        self.audioManager = AudioManager(details: details)
        super.init()
        if let ambianceDetails = details["ambiances"] as? [[String:AnyObject]] {
            self.ambiances = ambianceDetails.map {
                Ambiance(details: $0, audioManager: self.audioManager)
            }
        } else {
            self.ambiances = []
        }
        if let audibleDetails = details["audibles"] as? [[String:AnyObject]] {
            self.audibles = audibleDetails.map { [unowned self] in
                return Audible(details: $0, audioManager: self.audioManager, scriptingEngine: self.scripting)
            }
        } else {
            self.audibles = []
        }
        self.scripting.delegate = self
    }
    func run() {
        if !self.running {
            try? AudioKit.start()
        }
        self.ambiances.forEach { $0.applyPlayerPerspective(player: self.player, run: !self.running) }
        self.audibles.forEach { $0.applyPlayerPerspective(player: self.player, run: !self.running) }
        self.running = true
        
        self.scripting.update()// { (id: String, representation: ScriptRepresentation) in
        
    }
    func playerMovement(speed: CGFloat, rotation: CGFloat) {
        self.player.set(speed: speed, direction: self.player.direction + (rotation / 10.0))
        let dx: CGFloat = cos(self.player.direction)*speed
        let dy: CGFloat = sin(self.player.direction)*speed
        self.player.pos.x += dx
        self.player.pos.y += dy
        self.player.updateScriptingContext(engine: self.scripting)

        self.run()
        //print("Speed: \(speed), Rotation: \(self.player.direction)")
    }
    func playerAction() {
        if let index = self.audibles.firstIndex(where: { (object: Audible) -> Bool in
            return (abs(object.pos.x - self.player.pos.x) < ActionProximity) && (abs(object.pos.y - self.player.pos.y) < ActionProximity)
            }) {
            self.scripting.removeRepresenation(for: self.audibles[index].id, object: self.audibles[index])
            self.audibles[index].kill()
            self.audibles.remove(at: index)
            self.actionAudioPlayer.play()
        }
    }
}

extension Level: ScriptingCallbackDelegate {
    func callback(representation: ScriptRepresentation) {
        if let p = representation.object as? Perspective {
            p.applyPlayerPerspective(player: self.player, run: false)
        }
        print("\(self.player.pos) \(self.player.direction) \(representation.lastState["pos"]!)")
    }
}
