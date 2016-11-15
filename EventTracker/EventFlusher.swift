//
//  EventFlusher.swift
//  EventTracker
//
//  Created by Billy Irwin on 11/9/16.
//  Copyright © 2016 becauseinc. All rights reserved.
//

import Foundation

public typealias EventFlushCompletion = ((Error?) -> Void)

public protocol EventFlusher {
    func flushEvents(events: [Event], completion: @escaping EventFlushCompletion)
}

public class LogFlusher: EventFlusher {
    
    public func flushEvents(events: [Event], completion: @escaping EventFlushCompletion) {
        for event in events {
            print(event.toString())
        }
        completion(nil)
    }
    
}
