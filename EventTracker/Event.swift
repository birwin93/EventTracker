//
//  Event.swift
//  EventLogger
//
//  Created by Billy Irwin on 11/9/16.
//  Copyright © 2016 becauseinc. All rights reserved.
//

import Foundation

/**
 Anything that conforms to Event must also 
 subclass NSObject to conform adhere to NSCoding
 */

@objc
public protocol Event: class, NSCoding {
    func toString() -> String
}
