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
    private var level: Level?
    var actionAudioPlayer: AVAudioPlayer = try! AVAudioPlayer(contentsOf: Bundle.main.url(forResource: "action01", withExtension: "mp3")!)

    override func viewDidLoad() {
        super.viewDidLoad()

        let levelDetailsURL = Bundle.main.url(forResource: "Level1", withExtension: "plist")!
        let dict = NSDictionary.init(contentsOf: levelDetailsURL)
        self.level = Level(details: dict as! [String : AnyObject])
        
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
            self.level!.run()
        }
        let touchGesture = UITapGestureRecognizer(target: self, action: Selector("viewTouch:"))
        touchGesture.numberOfTapsRequired = 1
        touchGesture.numberOfTouchesRequired = 1
        self.view.addGestureRecognizer(touchGesture)
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
            // cancel
        } else {
            self.level!.playerAction()
            self.actionAudioPlayer.play()
        }
    }
}

extension GameViewController: ControlDelegate {
    func movement(speed: CGFloat, rotation: CGFloat) {
        guard let level = self.level else {
            return
        }
        level.playerMovement(speed: speed / 10.0, rotation: rotation / 10.0)
    }
    func action() {
        self.level!.playerAction()
        self.actionAudioPlayer.play()
}
}
