//
//  EventStore.swift
//  EventLogger
//
//  Created by Billy Irwin on 11/9/16.
//  Copyright © 2016 becauseinc. All rights reserved.
//

import Foundation

public protocol EventStore {
    func storeEvent(event: Event)
    func allEvents() -> [Event]
    func deleteEvents()
}

public class InMemoryEventStore: EventStore {
    
    private var cache = [Event]()
    
    public func storeEvent(event: Event) {
        self.cache.append(event)
    }
    
    public func allEvents() -> [Event] {
        return self.cache
    }
    
    public func deleteEvents() {
        self.cache.removeAll()
    }
    
}
