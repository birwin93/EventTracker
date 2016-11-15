//
//  TestEventTrackerUploader.swift
//  EventTracker
//
//  Created by Billy Irwin on 11/9/16.
//  Copyright © 2016 because. All rights reserved.
//

import Foundation

class TestFlusher : EventFlusher {
    func flushEvents(events: [Event], completion: @escaping EventFlushCompletion) {
        completion(nil)
    }
}

class TestAsyncFlusher : EventFlusher {
    func flushEvents(events: [Event], completion: @escaping EventFlushCompletion) {
        DispatchQueue.global(qos: .background).async {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
                completion(nil)
            })
        }
    }
}
