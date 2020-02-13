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
    var deathAudioPlayer: AVAudioPlayer = try! AVAudioPlayer(contentsOf: Bundle.main.url(forResource: "death01", withExtension: "mp3")!)

    let synthesizer = AVSpeechSynthesizer()
    let utteranceRestarting = AVSpeechUtterance(string: "Restarting")

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        NotificationCenter.default.addObserver(forName: Level.deathNotification, object: nil, queue: OperationQueue.main) { (notification: Notification) in
            if let level = self.level {
                self.deathAudioPlayer.play()
                self.running = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
                    level.stop()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 10, execute: {
                        self.utteranceRestarting.rate = 0.4
                        self.utteranceRestarting.volume = 0.8
                        self.utteranceRestarting.voice = AVSpeechSynthesisVoice(language: "en-US")
                        self.synthesizer.speak(self.utteranceRestarting)
                        self.restartLevel()
                    })
                })
            }
        }
        actionFailedAudioPlayer.volume = 0.03
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        self.restartLevel()
        
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
    func restartLevel() {
        self.levelManager!.restartLevel()
        self.running = true
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
