//
//  GameViewController.swift
//  jo
//
//  Created by Danila Parkhomenko on 04.02.2020.
//  Copyright © 2020 Danila Parkhomenko. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit
import AVKit
import AudioKit

class GameViewController: UIViewController {
    public var levelManager: LevelManager?
    private var running: Bool = false
    var level: Level? {
        get {
            if let levelManager = self.levelManager {
                return levelManager.currentLevel
            }
            return nil
        }
    }
    var actionAudioPlayer: AVAudioPlayer = try! AVAudioPlayer(contentsOf: Bundle.main.url(forResource: "action01", withExtension: "mp3")!)
    var actionFailedAudioPlayer: AVAudioPlayer = try! AVAudioPlayer(contentsOf: Bundle.main.url(forResource: "action03", withExtension: "mp3")!)
    var completionAudioPlayer: AVAudioPlayer = try! AVAudioPlayer(contentsOf: Bundle.main.url(forResource: "completion", withExtension: "mp3")!)
    var deathAudioPlayer: AVAudioPlayer = try! AVAudioPlayer(contentsOf: Bundle.main.url(forResource: "death01", withExtension: "mp3")!)

    let synthesizer = AVSpeechSynthesizer()
    let utteranceRestarting = AVSpeechUtterance(string: "Restarting")
    let level2 = AVSpeechUtterance(string: "Level one completed. Level 2")

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        NotificationCenter.default.addObserver(forName: Level.deathNotification, object: nil, queue: OperationQueue.main) { (notification: Notification) in
            self.deathAudioPlayer.play()
            self.breakEvent(utterance: self.utteranceRestarting, breakTime: .now() + 10) {
                self.levelManager!.restartLevel()
                self.running = true
            }
        }
        NotificationCenter.default.addObserver(forName: Level.levelCompletedNotification, object: nil, queue: OperationQueue.main) { (notification: Notification) in
            self.completionAudioPlayer.play()
            self.breakEvent(utterance: self.level2, breakTime: .now() + 1) {
                self.levelManager!.loadLevel(name: "Level2", callback: { (level: Level) in
                    self.running = true
                })
            }
        }
        actionFailedAudioPlayer.volume = 0.03
        completionAudioPlayer.volume = 0.6
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        self.running = true

        if let view = self.view as! SKView? {
            // Load the SKScene from 'GameScene.sks'
            if let scene = SKScene(fileNamed: "GameScene") {
                // Set the scale mode to scale to fit the window
                scene.scaleMode = .aspectFill
                
                // Present the scene
                view.presentScene(scene)
                (scene as! GameScene).controlDelegate = self
            }
            
            view.ignoresSiblingOrder = true
            
            view.showsFPS = true
            view.showsNodeCount = true
            self.levelManager!.currentLevel!.run()
        }
        let touchGesture = UITapGestureRecognizer(target: self, action: Selector(stringLiteral: "viewTouch:"))
        touchGesture.numberOfTapsRequired = 1
        touchGesture.numberOfTouchesRequired = 1
        self.view.addGestureRecognizer(touchGesture)
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    @objc func viewTouch(_ touch: UITapGestureRecognizer) -> Void {
        if self.actionAudioPlayer.isPlaying {
            // cooldown
            if self.actionFailedAudioPlayer.isPlaying {
                self.actionFailedAudioPlayer.currentTime = 0
            } else {
                self.actionFailedAudioPlayer.play()
            }
        } else {
            self.level!.playerAction()
            self.actionAudioPlayer.play()
        }
    }
    
    func breakEvent(utterance: AVSpeechUtterance, breakTime: DispatchTime, callback: @escaping () -> Void) {
        guard let level = self.level else { return }
        self.running = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
            level.stop()
            DispatchQueue.main.asyncAfter(deadline: breakTime, execute: {
                utterance.rate = 0.4
                utterance.volume = 0.8
                utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                self.synthesizer.speak(utterance)
                callback()
            })
        })
    }
}

extension GameViewController: ControlDelegate {
    func movement(speed: CGFloat, rotation: CGFloat) {
        guard running, let level = self.level else {
            return
        }
        level.playerMovement(speed: speed / 10.0, rotation: rotation / 10.0)
    }
    func action() {
        guard running else {
            return
        }
        self.level!.playerAction()
        self.actionAudioPlayer.play()
    }
}
