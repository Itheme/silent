//
//  LevelManager.swift
//  jo
//
//  Created by Danila Parkhomenko on 13.02.2020.
//  Copyright © 2020 Danila Parkhomenko. All rights reserved.
//

import UIKit

// ensures seemless level loading and switching
class LevelManager: NSObject {
    //static let loadedNotification = NSNotification.Name("levelLoaded")
    var audioManager: AudioManager = AudioManager()
    var currentLevelName: String?
    var currentLevel: Level?
    override init() {
        super.init()
    }
    func loadLevel(name: String, callback: @escaping (_ level: Level) -> Void) {
        let details = self.levelDetails(levelName: name)
//        if let previousLevel = self.currentLevel {
//            if name != previousLevel.name {
//                self.audioManager.stop()
//            }
//        }
        DispatchQueue.global(qos: .background).async {
            let level = self.loadLevelSync(name: name, details: details, audio: self.audioManager)
            DispatchQueue.main.async {
                callback(level)
            }
        }
    }
    func levelDetails(levelName: String) -> [String: AnyObject] {
        let levelDetailsURL = Bundle.main.url(forResource: levelName, withExtension: "plist")!
        let dict = NSDictionary.init(contentsOf: levelDetailsURL)
        return dict as! [String: AnyObject]
    }
    func loadLevelSync(name: String, details: [String: AnyObject], audio: AudioManager) -> Level {
        self.audioManager.addAllFiles(details: details)
        self.currentLevelName = name
        self.currentLevel = Level(name: name, details: details, audioManager: audio)
        return self.currentLevel!
    }
    func restartLevel() {
        guard let name = self.currentLevelName else { return }
        self.currentLevel = Level(name: name, details: self.levelDetails(levelName: name), audioManager: self.audioManager)
    }
}
