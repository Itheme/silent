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

protocol ScriptingCallbackDelegate {
    func callback(representation: ScriptRepresentation) -> Void
}

struct ScheduleRecord {
    let code: String
    let result: [AnyHashable: Any]?
    let callback: ((_ result: [AnyHashable: Any]?) -> Void)?
}

struct UpdateRecord {
    let updateScript: String
    let result: [AnyHashable: Any]?
    let representation: ScriptRepresentation
}

open class Scripting: NSObject {
    var collection: [String: ScriptRepresentation] = [:]
    private var loop: Int = 0
    var thread: Thread?
    var updateScheduled: Bool = false
    var scriptsScheduled: [ScheduleRecord] = []
    var shutdownScheduled: Bool = false
    var delegate: ScriptingCallbackDelegate?
    public init(details: [String:AnyObject]) {
        super.init()
        self.thread = Thread(block: { [unowned self] in
            let machine = JSVirtualMachine()!
            let context = JSContext(virtualMachine: machine)!
            let logClosure: @convention (block) (String, String, String, String) -> Void = { fmt, a, b, c in
                print(fmt, (a == "undefined") ?"":a, (b == "undefined") ?"":b, (c == "undefined") ?"":c)
            }
            context.objectForKeyedSubscript("console")?.setObject(logClosure, forKeyedSubscript: "log")
            while true {
                var scripts: [ScheduleRecord] = []
                var performShutdown: Bool = false
                var updateScripts: [UpdateRecord] = []
                DispatchQueue.main.sync {
                    scripts = self.scriptsScheduled
                    self.scriptsScheduled = []
                    if self.updateScheduled {
                        self.collection.forEach { (objectName: String, representation: ScriptRepresentation) in
                            if let script = representation.activeScript {
                                updateScripts.append(UpdateRecord(updateScript: "\(script)(\(objectName), \(objectName)Params, \(self.loop))", result: nil, representation: representation))
                            }
                        }
                        self.updateScheduled = false
                    }
                    performShutdown = self.shutdownScheduled
                }
                if performShutdown {
                    break
                }
                var dispatch: Bool = false
                scripts = scripts.map({ (record: ScheduleRecord) -> ScheduleRecord in
                    dispatch = dispatch || (record.callback != nil)
                    if let result = context.evaluateScript(record.code) {
                        return ScheduleRecord(code: record.code, result: result.toDictionary(), callback: record.callback)
                    }
                    return record
                })
                if dispatch {
                    DispatchQueue.main.sync {
                        for record in scripts {
                            if let callback = record.callback {
                                callback(record.result)
                            }
                        }
                    }
                }
                if updateScripts.count > 0 {
                    self.updateCollections(context: context, updateRecords: updateScripts)
                } else {
                    Thread.sleep(forTimeInterval: 0.1)
                }
            }
        })
        self.scheduleEvaluation(code: "var module = {}; var console = {};")
        if let scripts = details["scripts"] as? [String] {
            self.loadScripts(scripts)
        }
        self.thread?.start()
    }
    func loadScripts(_ scripts: [String]) {
        for scriptName in scripts {
            for bundle in Bundle.allBundles {
                if let url = bundle.url(forResource: scriptName, withExtension: "js") {
                    self.scheduleEvaluation(code: try! String(contentsOf: url))
                    break
                }
            }
        }
    }
    open func createRepresentation(for id: String, params: [String: AnyObject]?, object: StateCollector) {
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
        self.scheduleEvaluation(code: representationScript)
    }
    open func updateRepresentation(for id: String, object: StateCollector) {
        let state = object.collectState()!
        let serialized = try! JSONSerialization.data(withJSONObject: state, options: [])
        if let script = String(data: serialized, encoding: .utf8) {
            self.scheduleEvaluation(code: "\(id) = \(script);")
        }
    }
    open func removeRepresenation(for id: String, object: StateCollector) -> Void {
        self.collection.removeValue(forKey: id)
    }
    open func scheduleEvaluation(code: String) {
        return self.scriptsScheduled.append(ScheduleRecord(code: code, result: nil, callback: nil))
    }
    open func contextEvaluate(code: String, callback: @escaping (_ result: [AnyHashable : Any]?) -> Void) {
        self.scriptsScheduled.append(ScheduleRecord(code: code, result: nil, callback: callback))
    }
//    open func contextEvaluate(code: String) -> [AnyHashable : Any]? {
//        return self.context.evaluateScript(code)?.toDictionary()
//    }
//    open func evaluate(script: String, objectName: String) -> [String: AnyObject]? {
//        if let dict = self.contextEvaluate(code: "\(script)(\(objectName), \(objectName)Params, \(self.loop))") {
//            return dict as? [String : AnyObject]
//        }
//        return nil
//    }
    
    // evaluates all scripted objects on every few calls
    open func update() { //}(callback: (_ id: String, _ representation: ScriptRepresentation) -> Void) {
        self.loop += 1
        if (self.loop % 10) == 1 {
            self.updateScheduled = true
        }
    }
    func updateCollections(context: JSContext, updateRecords: [UpdateRecord]) {
        let updatedRecords = updateRecords.map { (record: UpdateRecord) -> UpdateRecord in
            return UpdateRecord(updateScript: record.updateScript, result: context.evaluateScript(record.updateScript)?.toDictionary(), representation: record.representation)
        }
        DispatchQueue.main.sync {
            for record in updatedRecords {
                if let dict = record.result as? [String: AnyObject] {
                    record.representation.lastState = dict
                    record.representation.object.applyState(state: dict)
                    if let callback = self.delegate {
                        callback.callback(representation: record.representation)
                    }
                }
            }
        }
    }
}
