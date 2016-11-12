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
    
    private let eventQueue = DispatchQueue(label: "com.because.eventTracker")
    
    init(configuration: EventTrackerConfiguration) {
        self.store = configuration.store
        self.uploader = configuration.uploader
        self.flushPolicy = configuration.flushPolicy
    }
    
    func trackEvent(event: Event, completion: ((Error?) -> Void)?) {
        self.async(block: {
            try self.preTrackActions()
            try self.store.storeEvent(event: event)
        }, completion: completion)
    }
    
    @objc func flushEvents(completion: ((Error?) -> Void)?) {
        self.async(block: {
            try self.flushStore()
        }, completion: completion)

    }
    
    func clearEvents(completion: ((Error?) -> Void)?) {
        self.async(block: {
            try self.clearStore()
        }, completion: completion)
    }
    
    // MARK: Private
    
    private func async(block: @escaping () throws -> Void, completion: ((Error?) -> Void)?) {
        eventQueue.async {
            do {
                try block()
                DispatchQueue.main.async {
                    if let c = completion {
                        c(nil)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    if let c = completion {
                        c(nil)
                    }
                }
            }
        }
    }
    
    private func preTrackActions() throws {
        switch self.flushPolicy {
        case .EventLimit(let limit):
            try self.flushStoreIfNecessary(limit: limit)
            break
        case .TimeInterval(let interval):
            self.startTimerIfNecessary(interval: interval)
            break
        case .Manual:
            break
        }
    }
    
    private func flushStoreIfNecessary(limit: Int) throws {
        let storeCount = try self.store.allEvents().count
        if storeCount >= limit {
            try self.flushStore()
        }
    }
    
    private func flushStore() throws {
        if let uploader = self.uploader {
            let events = try self.store.allEvents()
            uploader.uploadEvents(events: events)
            try self.clearStore()
        }
    }
    
    private func clearStore() throws {
        try self.store.deleteEvents()
    }
    
    private func startTimerIfNecessary(interval: TimeInterval) {
        guard let _ = self.flushTimer else {
            self.flushTimer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(flushEvents), userInfo: nil, repeats: true)
            return
        }
    }
    
}
