//
//  EventFlushPolicy.swift
//  EventTracker
//
//  Created by Billy Irwin on 11/9/16.
//  Copyright © 2016 because. All rights reserved.
//

import Foundation

enum EventFlushPolicy {
    case Manual
    case EventLimit(limit: Int)
    case TimeInterval(interval: TimeInterval)
}
