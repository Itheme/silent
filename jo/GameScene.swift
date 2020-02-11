//
//  GameScene.swift
//  jo
//
//  Created by Danila Parkhomenko on 04.02.2020.
//  Copyright © 2020 Danila Parkhomenko. All rights reserved.
//

import SpriteKit
import GameplayKit

protocol ControlDelegate {
    func movement(speed: CGFloat, rotation: CGFloat)
    func action()
}

// threshold value (in points) for when touch is considered a movement input from user
let MovementThreshold: CGFloat = 5
let MovementThresholdRotation: CGFloat = 20

class TouchTracker: NSObject {
    var touch: UITouch
    weak var scene: SKScene?
    let initialLocation: CGPoint
    var speed: CGFloat = 0
    init(touch: UITouch, in scene: SKScene) {
        self.touch = touch
        self.scene = scene
        self.initialLocation = touch.location(in: scene)
    }
}

class GameScene: SKScene {
    
    private var label : SKLabelNode?
    private var spinnyNode : SKShapeNode?
    var controlDelegate: ControlDelegate?
    var trackingTouches: [TouchTracker] = []
    var movementTracker: TouchTracker?
    override func didMove(to view: SKView) {
        
        // Get label node from scene and store it for use later
        self.label = self.childNode(withName: "//helloLabel") as? SKLabelNode
        if let label = self.label {
            label.alpha = 0.0
            label.run(SKAction.fadeIn(withDuration: 2.0))
        }
        
        // Create shape node to use during mouse interaction
        let w = (self.size.width + self.size.height) * 0.05
        self.spinnyNode = SKShapeNode.init(rectOf: CGSize.init(width: w, height: w), cornerRadius: w * 0.3)
        
        if let spinnyNode = self.spinnyNode {
            spinnyNode.lineWidth = 2.5
            
            spinnyNode.run(SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat(Double.pi), duration: 1)))
            spinnyNode.run(SKAction.sequence([SKAction.wait(forDuration: 0.5),
                                              SKAction.fadeOut(withDuration: 0.5),
                                              SKAction.removeFromParent()]))
        }
    }
    
    func touchDown(touch: UITouch) {
        let tracker = TouchTracker(touch: touch, in: self)
        self.trackingTouches.append(tracker)
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = tracker.initialLocation
            n.strokeColor = SKColor.green
            self.addChild(n)
        }
    }
    
    func touchMoved(touch: UITouch) {
        let pos = touch.location(in: self)
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.blue
            self.addChild(n)
        }
        guard let tracker = self.trackingTouches.first(where: { (t: TouchTracker) -> Bool in
            return t.touch == touch
        }) else {
            return
        }
        guard let control = self.controlDelegate else { return }
        if self.movementTracker == nil {
            if (abs(pos.x - tracker.initialLocation.x) > MovementThresholdRotation) || (abs(pos.y - tracker.initialLocation.y) > MovementThreshold) {
                self.movementTracker = tracker
            } else {
                return
            }
        }
        if let movementTracker = self.movementTracker {
            if movementTracker == tracker {
                tracker.speed = (pos.y - tracker.initialLocation.y) / self.size.height
                let rotation = (abs(pos.x - tracker.initialLocation.x) > MovementThresholdRotation) ?((pos.x - tracker.initialLocation.x) / self.size.width):0
                control.movement(speed: tracker.speed, rotation: rotation)
            }
        }
    }
    
    func touchUp(touch: UITouch, cancelled: Bool) {
        if let index = self.trackingTouches.firstIndex(where: { (t: TouchTracker) -> Bool in
            return t.touch == touch
        }) {
            let tracker = self.trackingTouches[index]
            let pos = touch.location(in: self)
            if let control = self.controlDelegate {
                if tracker == self.movementTracker {
                    control.movement(speed: 0, rotation: cancelled ?0:((pos.x - touch.previousLocation(in: self).x) / self.size.width))
                    self.movementTracker = nil
                } else {
                    if (!cancelled) {
                        control.action()
                    }
                }
            }
            self.trackingTouches.remove(at: index)
            if let n = self.spinnyNode?.copy() as! SKShapeNode? {
                n.position = pos
                n.strokeColor = SKColor.red
                self.addChild(n)
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let label = self.label {
            label.run(SKAction.init(named: "Pulse")!, withKey: "fadeInOut")
        }
        
        for t in touches { self.touchDown(touch: t) }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            self.touchMoved(touch: t)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(touch: t, cancelled: false) }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(touch: t, cancelled: true) }
    }
    
    override func update(_ currentTime: TimeInterval) {
        guard let control = self.controlDelegate else {
            return
        }
        if let tracker = self.movementTracker {
            control.movement(speed: tracker.speed, rotation: 0)
        } else {
            control.movement(speed: 0, rotation: 0)
        }
    }
}
