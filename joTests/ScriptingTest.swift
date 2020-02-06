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
    var contextEvaluationResultOverride: [AnyHashable : Any]?
    var lastContextEvalScript: String?
    
    var evaluationResultOverride: [String : AnyObject]?
    var lastEvaluatedScript: String?
    var lastEvaluatedScriptObjectName: String?
    override public func evaluate(script: String, objectName: String) -> [String : AnyObject]? {
        if self.evaluationResultOverride != nil {
            self.lastEvaluatedScript = script
            self.lastEvaluatedScriptObjectName = objectName
            return self.evaluationResultOverride
        }
        return super.evaluate(script: script, objectName: objectName)
    }
    override public func contextEvaluate(code: String) -> [AnyHashable : Any]? {
        if (self.contextEvaluationResultOverride != nil) {
            self.lastContextEvalScript = code
            return self.contextEvaluationResultOverride
        }
        return super.contextEvaluate(code: code)
    }
}

class EntityMockup: NSObject, StateCollector {
    var state: [String: AnyObject] = ["state": "value"] as [String: AnyObject]
    public func collectState() -> [String : AnyObject]? {
        return state
    }
    public func applyState(state: [String : AnyObject]) {
        self.state = state
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
        let dict = ["scripts": ["behaviourScript"]] as [String: AnyObject]
        let engine = ScriptingMockup(details: dict)
        let representation = engine.representation(for: "entity", params: ["p": "value" as AnyObject], object: self.entity)
        let representationDict = representation.toDictionary()
        XCTAssertNotNil(representationDict, "Game object representation created by scripting engine")
        XCTAssert(representationDict!["state"] as? String == "value", "Game object must have state values")
        let evalResult = engine.evaluate(script: "behaviourScript", objectName: "entity")
        XCTAssertNotNil(evalResult, "behaviourScript should return")
        XCTAssertNotNil(evalResult!["object"])
        XCTAssertNotNil(evalResult!["params"])
        XCTAssertNotNil(evalResult!["time"])
    }
    
    func testRepresentaion() {
        let engine = ScriptingMockup(details: [:])
        engine.contextEvaluationResultOverride = [:]
        XCTAssertNotNil(engine.representation(for: "entity", params: ["param": "paramValue" as AnyObject], object: self.entity))
        XCTAssertNotNil(engine.lastContextEvalScript)
        XCTAssert(engine.lastContextEvalScript! == "var entity = {\"state\":\"value\"}; var entityParams = {\"param\":\"paramValue\"};")
        self.entity.state["state"] = "value2" as AnyObject
        XCTAssertNotNil(engine.updateRepresentation(for: "entity", object: self.entity))
        XCTAssertNotNil(engine.lastContextEvalScript)
        XCTAssert(engine.lastContextEvalScript! == "entity = {\"state\":\"value2\"};")

        // testing state update
        engine.contextEvaluationResultOverride = nil
        let representation = engine.updateRepresentation(for: "entity", object: self.entity)
        let representationDict = representation.toDictionary()
        XCTAssertNotNil(representationDict, "Game object representation returned by scripting engine")
        XCTAssert(representationDict!["state"] as? String == "value2", "Game object state must be updated")
        
        engine.removeRepresenation(for: "entity", object: self.entity)
    }
    
    func testUpdate() {
        let dict = ["scripts": ["behaviourScript": "function(object, time) { return {'object': object, 'time': time }; }"]] as [String: AnyObject]
        let engine = ScriptingMockup(details: dict)
        engine.evaluationResultOverride = ["eval": "override"] as [String: AnyObject]
        self.entity.state["script"] = "behaviourScript" as AnyObject
        XCTAssertNotNil(engine.representation(for: "entity", params: ["param": "paramValue" as AnyObject], object: self.entity))
        var callbackRepresentation: ScriptRepresentation? = nil
        for _ in 0...100 {
            engine.update { (id: String, representation: ScriptRepresentation) in
                XCTAssertTrue(id == "entity")
                callbackRepresentation = representation
            }
            if callbackRepresentation != nil {
                XCTAssert(engine.lastEvaluatedScriptObjectName! == "entity")
                XCTAssert(engine.lastEvaluatedScript == "behaviourScript")
                return
            }
        }
        XCTFail("update hasn't ran behaviour script")
    }

}
