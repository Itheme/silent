//
//  Scripting.swift
//  jo
//
//  Created by Danila Parkhomenko on 05.02.2020.
//  Copyright © 2020 Danila Parkhomenko. All rights reserved.
//

import UIKit
import JavaScriptCore

public class ScriptRepresentation: NSObject {
    let object: StateCollector
    var lastState: [String: AnyObject]
    let activeScript: String?
    init(id: String, stateCollector: StateCollector) {
        self.object = stateCollector
        self.lastState = stateCollector.collectState()!
        self.activeScript = lastState["script"] as? String
    }
}

open class Scripting: NSObject {
    let machine = JSVirtualMachine()!
    let context: JSContext
    var collection: [String: ScriptRepresentation] = [:]
    private var loop: Int = 0
    public init(details: [String:AnyObject]) {
        self.context = JSContext(virtualMachine: self.machine)
        super.init()
        let _ = self.contextEvaluate(code: "var module = {}; var console = {};")
        if let scripts = details["scripts"] as? [String] {
            self.loadScripts(scripts)
        }
        let logClosure: @convention (block) (String, String, String, String) -> Void = { fmt, a, b, c in
            print(fmt, (a == "undefined") ?"":a, (b == "undefined") ?"":b, (c == "undefined") ?"":c)
        }
        self.context.objectForKeyedSubscript("console")?.setObject(logClosure, forKeyedSubscript: "log")
    }
    func loadScripts(_ scripts: [String]) {
        for scriptName in scripts {
            for bundle in Bundle.allBundles {
                if let url = bundle.url(forResource: scriptName, withExtension: "js") {
                    let _ = self.contextEvaluate(code: try! String(contentsOf: url))
                    break
                }
            }
        }
    }
    open func representation(for id: String, params: [String: AnyObject]?, object: StateCollector) -> JSValue {
        let representation = ScriptRepresentation(id: id, stateCollector: object)
        self.collection[id] = representation
        let serializedState = try! JSONSerialization.data(withJSONObject: representation.lastState, options: [])
        let scriptStateBody = String(data: serializedState, encoding: .utf8)!
        var representationScript = "var \(id) = \(scriptStateBody);"
        if let p = params {
            let serializedParams = try! JSONSerialization.data(withJSONObject: p, options: [])
            if let scriptParamsBody = String(data: serializedParams, encoding: .utf8) {
                representationScript = "\(representationScript) var \(id)Params = \(scriptParamsBody);"
            }
        }
        let _ = self.contextEvaluate(code: representationScript)
        return self.context.objectForKeyedSubscript(id)
    }
    open func updateRepresentation(for id: String, object: StateCollector) -> JSValue {
        let state = object.collectState()!
        let serialized = try! JSONSerialization.data(withJSONObject: state, options: [])
        if let script = String(data: serialized, encoding: .utf8) {
            self.contextEvaluate(code: "\(id) = \(script);")
        }
        return self.context.objectForKeyedSubscript(id)
    }
    open func removeRepresenation(for id: String, object: StateCollector) -> Void {
        self.collection.removeValue(forKey: id)
    }
    open func contextEvaluate(code: String) -> [AnyHashable : Any]? {
        return self.context.evaluateScript(code)?.toDictionary()
    }
    open func evaluate(script: String, objectName: String) -> [String: AnyObject]? {
        if let dict = self.contextEvaluate(code: "\(script)(\(objectName), \(objectName)Params, \(self.loop))") {
            return dict as? [String : AnyObject]
        }
        return nil
    }
    
    // evaluates all scripted objects on every few calls
    open func update(callback: (_ id: String, _ representation: ScriptRepresentation) -> Void) {
        self.loop += 1
        if (self.loop % 10) == 0 {
            self.collection.forEach { (id: String, representation: ScriptRepresentation) in
                if let script = representation.activeScript {
                    if let dict = self.evaluate(script: script, objectName: id) {
                        representation.lastState = dict
                        representation.object.applyState(state: representation.lastState)
                        callback(id, representation)
                    }
                }
            }
        }
    }
}
