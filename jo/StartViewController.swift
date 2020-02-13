//
//  StartViewController.swift
//  jo
//
//  Created by Danila Parkhomenko on 13.02.2020.
//  Copyright © 2020 Danila Parkhomenko. All rights reserved.
//

import UIKit

class StartViewController: UIViewController {
    let defaults = UserDefaults()
    var levelName: String?
    let levelManager = LevelManager()
    @IBOutlet weak var containerView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //todo: if let version = defaults.value(forKey: "version") as? String // check if levelling system is compatible
        self.levelName = (self.defaults.value(forKey: "level") as? String) ?? "Level1"
        //todo: if let levelState = self.defaults.value(forKey: "levelState") as? [String: AnyObject] { restore level state
        //todo: present an option for onboarding
        self.levelManager.loadLevel(name: self.levelName!) { (level: Level) in
            self.performSegue(withIdentifier: "play", sender: nil)
        }
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//        }
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let gameVC = segue.destination as? GameViewController {
            gameVC.levelManager = self.levelManager
        }
    }
}
