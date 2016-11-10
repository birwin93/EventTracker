//
//  EventTracker.swift
//  EventTracker
//
//  Created by Billy Irwin on 11/9/16.
//  Copyright © 2016 becauseinc. All rights reserved.
//

import Foundation

public struct EventTrackerConfiguration {
    let store: EventStore
    let uploader: EventTrackerUploader?
    let flushPolicy: EventFlushPolicy
}

public enum EventTrackerError: Error {
    case noUploader
}

public final class EventTracker {
    
    private let store: EventStore
    private let uploader: EventTrackerUploader?
    private let flushPolicy: EventFlushPolicy
    
    private var flushTimer: Timer?
    
    init(configuration: EventTrackerConfiguration) {
        self.store = configuration.store
        self.uploader = configuration.uploader
        self.flushPolicy = configuration.flushPolicy
    }
    
    func trackEvent(event: Event) {
        store.storeEvent(event: event)
        
        switch self.flushPolicy {
        case .EventLimit(let limit):
            self.flushIfStoreIsAtLimit(limit: limit)
            break
        case .TimeInterval(let interval):
            self.startTimerIfNecessary(interval: interval)
            break
        case .Manual:
            break
        }
        
    }
    
    @objc
    func flushEvents() {
        guard let uploader = self.uploader else { return }
        let events = store.allEvents()
        uploader.uploadEvents(events: events)
        self.clearEvents()
    }
    
    func clearEvents() {
        store.deleteEvents()
    }
    
    // MARK: Private
    
    private func flushIfStoreIsAtLimit(limit: Int) {
        if store.allEvents().count >= limit {
            self.flushEvents()
        }
    }
    
    private func startTimerIfNecessary(interval: TimeInterval) {
        guard let _ = self.flushTimer else {
            self.flushTimer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(flushEvents), userInfo: nil, repeats: true)
            return
        }
    }
    
}
