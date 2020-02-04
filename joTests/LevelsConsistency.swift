//
//  LevelsConsistency.swift
//  joTests
//
//  Created by Danila Parkhomenko on 04.02.2020.
//  Copyright © 2020 Danila Parkhomenko. All rights reserved.
//

import XCTest
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
            guard ambianceDetails.allSatisfy(Ambiance.checkConsistency($0)) else {
                return false
            }
        }
        if let audibleDetails = details["audibles"] as? [[String:AnyObject]] {
            guard audibleDetails.allSatisfy(Audible.checkConsistency($0)) else {
                return false
            }
        }
        return true
    }
}

extension Player: ConsistencyChecker {
    static func checkConsistency(details: [String:AnyObject]) -> Bool {
        return true
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
