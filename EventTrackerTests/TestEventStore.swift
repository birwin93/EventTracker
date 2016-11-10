//
//  TestEventStore.swift
//  EventTracker
//
//  Created by Billy Irwin on 11/9/16.
//  Copyright © 2016 because. All rights reserved.
//

import Foundation

class TestEventStore : EventStore {
    
    private var cache = [Event]()
    
    func storeEvent(event: Event) {
        self.cache.append(event)
    }
    
    func allEvents() -> [Event] {
        return self.cache
    }
    
    func deleteEvents() {
        self.cache.removeAll()
    }
    
}
