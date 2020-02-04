//
//  Player.swift
//  jo
//
//  Created by Danila Parkhomenko on 04.02.2020.
//  Copyright © 2020 Danila Parkhomenko. All rights reserved.
//

import UIKit
import JavaScriptCore

public class Player: NSObject {
    var pos: CGPoint
    var direction: CGFloat // angle in radians
    var scriptRepresentation: JSValue
    var posScriptRepresentation: JSValue
    init(initialPoint: CGPoint, initialDirection: CGFloat, scriptRepresentation: JSValue) {
        self.pos = initialPoint
        self.direction = initialDirection
        self.scriptRepresentation = scriptRepresentation
        self.posScriptRepresentation = self.scriptRepresentation.objectForKeyedSubscript("pos")
    }
    func updateJSContext() {
        self.posScriptRepresentation.setValue(pos.x, forProperty: "x")
        self.posScriptRepresentation.setValue(pos.y, forProperty: "y")
        self.scriptRepresentation.setValue(direction, forProperty: "direction")
    }

}
