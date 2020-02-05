//
//  LevelsConsistency.swift
//  joTests
//
//  Created by Danila Parkhomenko on 04.02.2020.
//  Copyright © 2020 Danila Parkhomenko. All rights reserved.
//

import XCTest
import AVKit
import jo

protocol ConsistencyChecker {
    static func checkConsistency(details: [String:AnyObject]) -> Bool
}

extension Level: ConsistencyChecker {
    static func checkConsistency(details: [String:AnyObject]) -> Bool {
        if let playerDetails = details["player"] as? [String:AnyObject] {
            guard Player.checkConsistency(details: playerDetails) else {
                return false
            }
        }
        if let ambianceDetails = details["ambiances"] as? [[String:AnyObject]] {
            XCTAssert(ambianceDetails.allSatisfy { (details: [String : AnyObject]) -> Bool in
                return Ambiance.checkConsistency(details: details)
            })
        }
        if let audibleDetails = details["audibles"] as? [[String:AnyObject]] {
            XCTAssert(audibleDetails.allSatisfy { (details: [String : AnyObject]) -> Bool in
                Audible.checkConsistency(details: details)
            })
        }
        return true
    }
}

extension Player: ConsistencyChecker {
    static func checkConsistency(details: [String:AnyObject]) -> Bool {
        return true
    }
}

extension AbstractAudible {
    static func genericCheckConsistency(details: [String:AnyObject]) -> Bool {
        if let urlString = details["url"] as? String {
            if let url = Bundle.main.url(forResource: urlString, withExtension: "mp3") {
                if let _ = try? AVAudioPlayer(contentsOf: url) {
                    if let _ = details["pos"] as? String {
                        return true
                    }
                    if let _ = details["pos"] as? [String:CGFloat] {
                        return true
                    }
                    XCTFail("Pos not present")
                }
                XCTFail("Unable to load track \(urlString)")
            }
            XCTFail("Track \(urlString) not found")
        }
        XCTFail("Url not present")
        return false
    }
}

extension Ambiance: ConsistencyChecker {
    static func checkConsistency(details: [String:AnyObject]) -> Bool {
        return AbstractAudible.genericCheckConsistency(details: details)
    }
}

extension Audible: ConsistencyChecker {
    static func checkConsistency(details: [String:AnyObject]) -> Bool {
        return AbstractAudible.genericCheckConsistency(details: details)
    }
}

class LevelsConsistency: XCTestCase {

    override func setUp() {
    }

    override func tearDown() {
    }

    func testExample() {
        let levelDetailsURL = Bundle.main.url(forResource: "Level1", withExtension: "plist")!
        let dict = NSDictionary.init(contentsOf: levelDetailsURL)
        XCTAssert(Level.checkConsistency(details: dict as! [String : AnyObject]))
    }
}
