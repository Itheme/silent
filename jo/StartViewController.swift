//
//  StartViewController.swift
//  jo
//
//  Created by Danila Parkhomenko on 13.02.2020.
//  Copyright © 2020 Danila Parkhomenko. All rights reserved.
//

import UIKit
import PureLayout

enum LoadingProcess {
    case halted
    case onboarding
    case previousLevel
    case completeRestart
}

class StartViewController: UIViewController {
    let defaults = UserDefaults()
    var levelName: String?
    let levelManager = LevelManager()
    @IBOutlet weak var containerView: UIView!
    weak var onboardingLabel: UILabel?
    weak var questionLabel: UILabel?
    var loadingProcess: LoadingProcess = .previousLevel
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var label = self.defaultLabel(with: "Tap for tutorial")
        label.alpha = 0
        self.onboardingLabel = label
        self.containerView.addSubview(label)
        label.autoPinEdge(toSuperviewEdge: .top, withInset: 8)
        label.autoPinEdge(toSuperviewEdge: .left, withInset: 8)
        label.autoPinEdge(toSuperviewEdge: .right, withInset: 8)
        self.containerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(containerViewTapped(gesture:))))
        label = self.defaultLabel(with: "Tap again to confirm")
        label.alpha = 0
        self.questionLabel = label
        self.containerView.addSubview(label)
        label.autoPinEdge(.top, to: .bottom, of: self.onboardingLabel!)
        label.autoPinEdge(toSuperviewEdge: .left, withInset: 8)
        label.autoPinEdge(toSuperviewEdge: .right, withInset: 8)
        self.containerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(containerViewTapped(gesture:))))
        //todo: menu
        //todo: if let version = defaults.value(forKey: "version") as? String // check if levelling system is compatible
        self.levelName = (self.defaults.value(forKey: "level") as? String) ?? "Level1"
        //todo: if let levelState = self.defaults.value(forKey: "levelState") as? [String: AnyObject] { restore level state
        //todo: present an option for onboarding
        self.levelManager.loadLevel(name: self.levelName!) { (level: Level) in
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                if self.loadingProcess == .previousLevel {
                    self.performSegue(withIdentifier: "play", sender: nil)
                }
            }
        }
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//        }
    }
    
    @objc func containerViewTapped(gesture: UITapGestureRecognizer) {
        if self.loadingProcess == .halted {
            self.loadingProcess = .onboarding
            self.levelManager.loadLevel(name: "onboarding01") { (level: Level) in
                self.performSegue(withIdentifier: "play", sender: nil)
            }
        } else {
            self.loadingProcess = .halted
            UIView.animate(withDuration: 0.2) {
                self.questionLabel!.alpha = 1.0
            }
        }
    }
    
    func defaultLabel(with text: String) -> UILabel {
        let label = UILabel()
        label.textColor = UIColor.white
        label.font = UIFont.systemFont(ofSize: 20)
        label.text = text
        label.autoSetDimension(.height, toSize: 30)
        return label
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIView.animate(withDuration: 0.5) {
            self.onboardingLabel!.alpha = 1.0
        }
    }
    
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let gameVC = segue.destination as? GameViewController {
            gameVC.levelManager = self.levelManager
            if self.loadingProcess == .onboarding {
                gameVC.startOnboarding(stage: .moveForward)
            } else {
                gameVC.availableActions = [.moveForward, .moveBackward, .turn, .strike]
            }
        }
    }
}
