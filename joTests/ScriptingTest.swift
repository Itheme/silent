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
    var evaluationCallbackOverride: ((_ result: [AnyHashable: Any]?) -> Void)?
    override public func passToMainThread(_ block: @escaping () -> Void) {
        block()
    }
    override public func setupWorkerThread() {
        // preventing thread to start
    }
    override public func scheduleEvaluation(code: String) {
        if let callback = self.evaluationCallbackOverride {
            self.scheduleEvaluation(code: code, callback: callback)
        } else {
            super.scheduleEvaluation(code: code)
        }
    }
//    override public func evaluate(script: String, objectName: String) -> [String : AnyObject]? {
//        if self.evaluationResultOverride != nil {
//            self.lastEvaluatedScript = script
//            self.lastEvaluatedScriptObjectName = objectName
//            return self.evaluationResultOverride
//        }
//        return super.evaluate(script: script, objectName: objectName)
//    }
//    override public func contextEvaluate(code: String) -> [AnyHashable : Any]? {
//        if (self.contextEvaluationResultOverride != nil) {
//            self.lastContextEvalScript = code
//            return self.contextEvaluationResultOverride
//        }
//        return super.contextEvaluate(code: code)
//    }
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

    func testScriptsLoading() {
        let dict = ["scripts": ["behaviourScript"]] as [String: AnyObject]
        let engine = ScriptingMockup(details: dict)
        var representationDict: [AnyHashable: Any]? = nil
        var representationParamsDict: [AnyHashable: Any]? = nil
        engine.createRepresentation(for: "entity", params: ["p": "value" as AnyObject], object: self.entity)
        engine.scheduleEvaluation(code: "entity;", callback: { (result: [AnyHashable: Any]?) in
            representationDict = result
        })
        engine.scheduleEvaluation(code: "entityParams;", callback: { (result: [AnyHashable: Any]?) in
            representationParamsDict = result
            engine.scheduleShutdown()
        })
        engine.workerLoop()
        XCTAssertNotNil(representationDict, "Game object representation created by scripting engine")
        XCTAssertNotNil(representationParamsDict, "Game object params created by scripting engine")
        XCTAssert(representationDict!["state"] as? String == "value", "Game object must have state values")
        XCTAssert(representationParamsDict!["p"] as? String == "value", "Game object must have state values")
    }
    
    func testScriptsRunning() {
        let dict = ["scripts": ["behaviourScript"]] as [String: AnyObject]
        let engine = ScriptingMockup(details: dict)
        var evalResult: [AnyHashable: Any]? = nil
        engine.createRepresentation(for: "entity", params: ["p": "value" as AnyObject], object: self.entity)
        engine.scheduleEvaluation(code: "behaviourScript(entity, entityParams, 3)", callback: { (result: [AnyHashable: Any]?) in
            evalResult = result
            engine.scheduleShutdown()
        })
        engine.workerLoop()

        XCTAssertNotNil(evalResult, "behaviourScript should return")
        XCTAssertNotNil(evalResult!["object"])
        XCTAssertNotNil(evalResult!["params"])
        XCTAssertNotNil(evalResult!["time"])
    }
    
    func testRepresentaion() {
        let engine = ScriptingMockup(details: [:])
        engine.createRepresentation(for: "entity", params: ["param": "paramValue" as AnyObject], object: self.entity)
        self.entity.state["state"] = "value2" as AnyObject
        engine.updateRepresentation(for: "entity", object: self.entity)
        engine.removeRepresenation(for: "entity", object: self.entity)
        print(engine.scriptsScheduled)
        XCTAssert(engine.scriptsScheduled.count == 3)
        // engine.scriptsScheduled[0]: engine setup
        XCTAssert(engine.scriptsScheduled[1].code == "var entity = {\"state\":\"value\"}; var entityParams = {\"param\":\"paramValue\"};")
        XCTAssert(engine.scriptsScheduled[2].code == "entity = {\"state\":\"value2\"};")
    }

    func testUpdateTasks() {
        let dict = ["scripts": ["behaviourScript": "function(object, time) { return {'object': object, 'time': time }; }"]] as [String: AnyObject]
        let engine = ScriptingMockup(details: dict)
        self.entity.state["script"] = "behaviourScript" as AnyObject
        engine.createRepresentation(for: "entity", params: ["param": "paramValue" as AnyObject], object: self.entity)
        for _ in 0...100 {
            engine.update()
        }
        var tasks = engine.obtainTasks()!
        XCTAssert(tasks.scripts.count == 2)
        XCTAssert(tasks.scripts[0].code == "var module = {}; var console = {};", "Initial environment setup")
        // tasks.scripts[1] representation creation
        XCTAssert(tasks.updateScripts.count == 1)
        XCTAssert(tasks.updateScripts[0].updateScript == "behaviourScript(entity, entityParams, 101)", "update scheduled for a single entity")
            
        engine.createRepresentation(for: "entity2", params: ["param": "paramValue" as AnyObject], object: self.entity)
        for _ in 0...100 {
            engine.update()
        }
        tasks = engine.obtainTasks()!
        XCTAssert(tasks.scripts.count == 1) // previous tasks were removed
        
        engine.createRepresentation(for: "entity3", params: ["param": "paramValue" as AnyObject], object: self.entity)
        for _ in 0...100 {
            engine.update()
        }
        engine.scheduleShutdown()
        XCTAssertNil(engine.obtainTasks()) // no tasks when shutdown is scheduled
    }
    func testUpdateTasksExecution() {
        let dict = ["scripts": ["behaviourScript": "function(object, time) { return {'object': object, 'time': time }; }"]] as [String: AnyObject]
        let engine = ScriptingMockup(details: dict)
        self.entity.state["script"] = "behaviourScript" as AnyObject
        engine.createRepresentation(for: "entity", params: ["param": "paramValue" as AnyObject], object: self.entity)
        for _ in 0...100 {
            engine.update()
        }
        engine.scheduleShutdown()
        engine.workerLoop()
    }
}
