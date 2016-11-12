//
//  Event.swift
//  EventLogger
//
//  Created by Billy Irwin on 11/9/16.
//  Copyright © 2016 becauseinc. All rights reserved.
//

import Foundation

@objc
public protocol Event: class, NSCoding {
    func toString() -> String
}
