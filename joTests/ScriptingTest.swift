//
//  ScriptingTest.swift
//  joTests
//
//  Created by Danila Parkhomenko on 05.02.2020.
//  Copyright © 2020 Danila Parkhomenko. All rights reserved.
//

import XCTest
import jo

public class ScriptingMockup: Scripting {
    
}

class EntityMockup: NSObject, StateCollector {
    public func collectState() -> [String : AnyObject]? {
        return ["state": "value"] as [String: AnyObject]
    }
    public func applyState(state: [String : AnyObject]) {
        //
    }
}

class ScriptingTest: XCTestCase {

    var engine: Scripting?
    var entity: EntityMockup = EntityMockup() // some game object with a state
    override func setUp() {
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testScriptsLoadingAndRunning() {
        let dict = ["scripts": ["behaviourScript": "function(object, time) { return {'object': object, 'time': time }; }"]] as [String: AnyObject]
        let engine = ScriptingMockup(details: dict)
        let representation = engine.representation(for: "entity", object: self.entity)
        let representationDict = representation.toDictionary()
        XCTAssertNotNil(representationDict, "Game object representation created by scripting engine")
        XCTAssert(representationDict!["state"] as? String == "value", "Game object must have state values")
        let evalResult = engine.evaluate(script: "behaviourScript", objectName: "entity")
        XCTAssertNotNil(evalResult, "behaviourScript should return")
        XCTAssertNotNil(evalResult!["object"])
        XCTAssertNotNil(evalResult!["time"])
    }
    

}
