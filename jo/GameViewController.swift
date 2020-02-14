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

enum OnboardingStage {
    case none
    case moveForward
    case moveBackward
    case turn
    case action
    case die
}

class GameViewController: UIViewController {
    public var levelManager: LevelManager?
    public var availableActions: ControlActions = [.moveForward, .moveBackward, .turn, .strike]
    private var running: Bool = false
    var level: Level? {
        get {
            if let levelManager = self.levelManager {
                return levelManager.currentLevel
            }
            return nil
        }
    }
    var onboardingStage: OnboardingStage = .none
    var actionAudioPlayer: AVAudioPlayer = try! AVAudioPlayer(contentsOf: Bundle.main.url(forResource: "action01", withExtension: "mp3")!)
    var actionFailedAudioPlayer: AVAudioPlayer = try! AVAudioPlayer(contentsOf: Bundle.main.url(forResource: "action03", withExtension: "mp3")!)
    var completionAudioPlayer: AVAudioPlayer = try! AVAudioPlayer(contentsOf: Bundle.main.url(forResource: "completion", withExtension: "mp3")!)
    var deathAudioPlayer: AVAudioPlayer = try! AVAudioPlayer(contentsOf: Bundle.main.url(forResource: "death01", withExtension: "mp3")!)

    let synthesizer = AVSpeechSynthesizer()
    let utteranceRestarting = AVSpeechUtterance(string: "Restarting")
    let utteranceStartOnboarding01 = AVSpeechUtterance(string: "Swipe up and hold to move forward")
    let utteranceStartOnboarding02 = AVSpeechUtterance(string: "Swipe down and hold to move backwards")
    let utteranceStartOnboarding03 = AVSpeechUtterance(string: "Swipe left or right to turn")
    let utteranceStartOnboarding04 = AVSpeechUtterance(string: "Tap at the appropriate time to collect sound source")
    let utteranceStartOnboarding05 = AVSpeechUtterance(string: "Move, until consumed in the noise. This is how you die")
    let level2 = AVSpeechUtterance(string: "Level one completed. Level 2")
    var lastMoveStartTime: CFAbsoluteTime?

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
            switch self.onboardingStage {
            case .none:
                self.completionAudioPlayer.play()
                self.breakEvent(utterance: self.level2, breakTime: .now() + 1) {
                    self.levelManager!.loadLevel(name: "Level2", callback: { (level: Level) in
                        self.running = true
                    })
                }
                break
            case .action:
                self.startOnboarding(stage: .die)
                break
            default:
                break
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
        let touchGesture = UITapGestureRecognizer(target: self, action: #selector(viewTouch(_:)))
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
                self.playUtterance(utterance: utterance)
                callback()
            })
        })
    }
    
    func playUtterance(utterance: AVSpeechUtterance) {
        print(utterance.speechString)
        utterance.rate = 0.4
        utterance.volume = 0.8
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        self.synthesizer.speak(utterance)
    }
    
    func startOnboarding(stage: OnboardingStage) {
        self.lastMoveStartTime = nil
        switch stage {
        case .moveForward:
            self.playUtterance(utterance: self.utteranceStartOnboarding01)
            self.onboardingStage = .moveForward
            self.availableActions = [.moveForward]
            break
        case .moveBackward:
            self.playUtterance(utterance: self.utteranceStartOnboarding02)
            self.onboardingStage = .moveBackward
            self.availableActions = [.moveBackward]
            break
        case .turn:
            self.playUtterance(utterance: self.utteranceStartOnboarding03)
            self.onboardingStage = .turn
            self.availableActions = [.turn]
            break
        case .action:
            if self.onboardingStage != .action {
                self.onboardingStage = .action
                self.levelManager?.loadLevel(name: "onboarding02", callback: { (level: Level) in
                    self.playUtterance(utterance: self.utteranceStartOnboarding04)
                    self.availableActions = [.strike]
                })
            }
            break
        case .die:
            if self.onboardingStage != .die {
                self.onboardingStage = .die
                self.levelManager?.loadLevel(name: "onboarding03", callback: { (level: Level) in
                    self.playUtterance(utterance: self.utteranceStartOnboarding05)
                    self.availableActions = [.moveForward, .moveBackward, .turn, .strike]
                })
            }
            break
        default:
            break
        }
        self.onboardingStage = stage
    }
}

extension GameViewController: ControlDelegate {
    func currentAvailableActions() -> ControlActions {
        return self.availableActions
    }
    func movement(speed: CGFloat, rotation: CGFloat) {
        guard running, let level = self.level else {
            return
        }
        if self.onboardingStage != .none {
            let time = CFAbsoluteTimeGetCurrent()
            switch self.onboardingStage {
            case .moveForward:
                if speed > 0 {
                    if let startTime = self.lastMoveStartTime {
                        if time - startTime > 4.0 {
                            self.startOnboarding(stage: .moveBackward)
                        }
                    } else {
                        self.lastMoveStartTime = time
                    }
                } else {
                    self.lastMoveStartTime = nil
                }
                break
            case .moveBackward:
                if speed < 0 {
                    if let startTime = self.lastMoveStartTime {
                        if time - startTime > 4.0 {
                            self.startOnboarding(stage: .turn)
                        }
                    } else {
                        self.lastMoveStartTime = time
                    }
                } else {
                    self.lastMoveStartTime = nil
                }
                break
            case .turn:
                if rotation != 0 {
                    if let startTime = self.lastMoveStartTime {
                        if time - startTime > 3.0 {
                            self.startOnboarding(stage: .action)
                        }
                    } else {
                        self.lastMoveStartTime = time
                    }
                }
                break
            //case .action:
                //
            default: break
                //
            }
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
