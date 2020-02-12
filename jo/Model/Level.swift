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

let ActionProximity: CGFloat = 5.0

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
        self.addFiles(fileDetails: details["audibles"] as? [[String:AnyObject]])
        self.addFiles(fileDetails: details["ambiances"] as? [[String:AnyObject]])
        AudioKit.output = self.mixer
    }
    func addFiles(fileDetails: [[String: AnyObject]]?) {
        guard let array = fileDetails else {
            return
        }
        for record in array {
            guard let fileName = record["url"] as? String else { continue }
            let ext = record["ext"] as? String ?? "mp3"
            if audioFiles[fileName] == nil {
                audioFiles[fileName] = try! AKAudioFile(forReading: Bundle.main.url(forResource: fileName, withExtension: ext)!)
            }
        }
    }
    func addPlayer(fileName: String) -> AKPlayer {
        let player = AKPlayer(audioFile: self.audioFiles[fileName]!)
        player.isLooping = true
        self.mixer.connect(input: player)
        return player
    }
    func stop() {
        self.mixer.stop()
        AudioKit.output = nil
    }
}

extension CGPoint {
    func distance(point: CGPoint) -> Float {
        let dx = self.x - point.x
        let dy = self.y - point.y
        return sqrtf(Float(dx * dx + dy * dy))
    }
}
public class Level: NSObject {
    static let deathNotification = NSNotification.Name("death")
    private var details: [String:AnyObject]
    let name: String
    var player: Player
    var ambiances: [Ambiance] = []
    var audibles: [Audible] = []
    var running: Bool = false
    let audioManager: AudioManager;
    let engine: AVAudioEngine = AVAudioEngine()
    let scripting: Scripting
    var actionAudioPlayer: AVAudioPlayer = try! AVAudioPlayer(contentsOf: Bundle.main.url(forResource: "action02", withExtension: "mp3")!)
    init(name: String, details: [String:AnyObject], audioManager: AudioManager?) {
        self.name = name
        self.details = details
        self.scripting = Scripting(details: details)
        let playerDetails = (details["player"] as? [String:AnyObject]) ?? [:]
        self.player = Player(initialPoint: (playerDetails["pos"] as? CGPoint) ?? CGPoint(x: 0, y: 0), initialDirection: (playerDetails["direction"] as? CGFloat) ?? 0, scriptingEngine: self.scripting)
        if let audio = audioManager {
            self.audioManager = audio
        } else {
            self.audioManager = AudioManager(details: details)
        }
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
//        AKPlayer(audioFile: <#T##AVAudioFile#>)
//        AKSampler()
//        AudioKit.output = AKMixer(oscillator, oscillator2)
    }
    func run() {
        if !self.running {
            try? AudioKit.start()
        }
        self.ambiances.forEach {
            $0.applyPlayerPerspective(player: self.player, run: !self.running)
            if $0.deadly, let radius = $0.deadlyRadius {
                let r = self.player.pos.distance(point: $0.pos)
                if ($0.inverted && (r > radius)) || (!$0.inverted && (r < radius)) {
                    NotificationCenter.default.post(name: Level.deathNotification, object: nil)
                }
            }
        }
        self.audibles.forEach { $0.applyPlayerPerspective(player: self.player, run: !self.running) }
        self.running = true
        
        self.scripting.update()// { (id: String, representation: ScriptRepresentation) in
    }
    func stop() {
        self.running = false
        self.player.stop()
        self.ambiances.forEach { $0.stop() }
        self.audibles.forEach { $0.stop() }
    }

    func playerMovement(speed: CGFloat, rotation: CGFloat) {
        self.player.set(speed: speed, direction: self.player.direction + (rotation * 0.5))
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
        print("\(self.player.pos) \(self.player.direction) \(representation.lastState)")
    }
}
