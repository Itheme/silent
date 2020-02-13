//
//  AudioManager.swift
//  jo
//
//  Created by Danila Parkhomenko on 13.02.2020.
//  Copyright © 2020 Danila Parkhomenko. All rights reserved.
//

import UIKit
import AudioKit

class AudioManager: NSObject {
    var audioFiles: [String: AKAudioFile] = [:]
    let mixer: AKMixer = AKMixer()
    override init() {
        super.init()
        AudioKit.output = self.mixer
    }
    func addAllFiles(details: [String: AnyObject]) {
        self.audioFiles = [:]
        self.addFiles(fileDetails: details["audibles"] as? [[String:AnyObject]])
        self.addFiles(fileDetails: details["ambiances"] as? [[String:AnyObject]])
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
