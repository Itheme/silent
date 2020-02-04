//
//  Player.swift
//  jo
//
//  Created by Danila Parkhomenko on 04.02.2020.
//  Copyright © 2020 Danila Parkhomenko. All rights reserved.
//

import UIKit

public class Player: NSObject {
    var pos: CGPoint
    var direction: CGPoint
    init(initialPoint: CGPoint, initialDirection: CGPoint) {
        self.pos = initialPoint
        self.direction = initialDirection
    }

}
