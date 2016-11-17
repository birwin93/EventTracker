//
//  EventTracker.swift
//  EventTracker
//
//  Created by Billy Irwin on 11/9/16.
//  Copyright © 2016 becauseinc. All rights reserved.
//

import Foundation

public typealias EventTrackerCompletion = ((Error?) -> Void)

public struct EventTrackerConfiguration {
    let store: EventStore
    let flusher: EventFlusher
    let flushPolicy: EventFlushPolicy
}

public enum EventTrackerError: Error {
    case noUploader
}

public class EventTracker {
    
    private let store: EventStore
    private let flusher: EventFlusher
    private let flushPolicy: EventFlushPolicy
    
    private var flushTimer: Timer?
    
    private let eventQueue = DispatchQueue(label: "com.because.eventTracker")
    
    private let operationQueue = { () -> OperationQueue in 
        let queue = OperationQueue()
        queue.name = "EventTrackerOperationQueue"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    public init(configuration: EventTrackerConfiguration) {
        self.store = configuration.store
        self.flusher = configuration.flusher
        self.flushPolicy = configuration.flushPolicy
    }
    
    // MARK: Public Methods
    
    public func trackEvent(event: Event) {
        self.trackEvent(event: event, completion: nil)
    }

    public func trackEvent(event: Event, completion: EventTrackerCompletion?) {
        let op = TrackEventOperation(event: event, tracker: self, completion: completion)
        self.operationQueue.addOperation(op)
    }

    public func flushEvents() {
        self.flushEvents(completion: nil)
    }

    public func flushEvents(completion: EventTrackerCompletion?) {
        let op = FlushOperation(tracker: self, completion: completion)
        self.operationQueue.addOperation(op)
    }

    public func clearEvents() {
        self.clearEvents(completion: nil)
    }

    public func clearEvents(completion: EventTrackerCompletion?) {
        let op = ClearOperation(tracker: self, completion: completion)
        self.operationQueue.addOperation(op)
    }

    // MARK: Helper Methods
        
    private func preTrackActions(completion: @escaping EventTrackerCompletion) {
        switch self.flushPolicy {
        case .EventLimit(let limit):
            self.flushStoreIfNecessary(limit: limit, completion: { (error) in
                completion(error)
            })
            break
        case .TimeInterval(let interval):
            self.startTimerIfNecessary(interval: interval)
            completion(nil)
            break
        case .Manual:
            completion(nil)
            break
        }
    }
    
    private func flushStoreIfNecessary(limit: Int, completion: @escaping EventTrackerCompletion) {
        self.store.allEvents { [weak self] (events, error) in
            if let err = error {
                completion(err)
            } else if events.count >= limit {
                self?.flushStore { (error) in
                    completion(error)
                }
            } else {
                completion(nil)
            }
        }
    }
    
    private func flushStore(completion: @escaping EventTrackerCompletion) {
        self.store.allEvents { [weak self] (events, error) in
            if let err = error {
                completion(err)
            } else {
                self?.flusher.flushEvents(events: events, completion: { [weak self] (error) in
                    if let err = error {
                        completion(err)
                    } else {
                        self?.clearStore(completion: completion)
                    }
                })
            }
        }
    }
    
    private func clearStore(completion: @escaping EventTrackerCompletion) {
        self.store.deleteEvents { (error) in
            completion(error)
        }
    }
    
    @objc private func flushEventsOnTimer() {
        self.flushEvents()
    }

    private func startTimerIfNecessary(interval: TimeInterval) {
        guard let _ = self.flushTimer else {
            self.flushTimer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(flushEventsOnTimer), userInfo: nil, repeats: true)
            return
        }
    }
    
    // MARK: Custom Operations
    
    private class AsyncBlockOperation : Operation {
        
        override var isAsynchronous: Bool {
            return true
        }
        
        private var _executing = false {
            willSet {
                willChangeValue(forKey: "isExecuting")
            }
            didSet {
                didChangeValue(forKey: "isExecuting")
            }
        }
        
        override var isExecuting: Bool {
            return _executing
        }
        
        private var _finished = false {
            willSet {
                willChangeValue(forKey: "isFinished")
            }
            didSet {
                didChangeValue(forKey: "isFinished")
            }
        }
        
        override var isFinished: Bool {
            return _finished
        }
        
        var completion: EventStoreCompletion?
        weak var tracker: EventTracker?
        
        init(tracker: EventTracker, completion: EventStoreCompletion?) {
            self.tracker = tracker
            self.completion = completion
        }
        
        override func start() {
            _executing = true
            execute()
        }
        
        func execute() {
            // subclasses override this and it MUST call self.finish()
            self.finish()
        }
        
        func finish() {
            _executing = false
            _finished = true
        }
    }
    
    private class TrackEventOperation : AsyncBlockOperation {
        
        var event: Event
        
        init(event: Event, tracker: EventTracker, completion: EventStoreCompletion?) {
            self.event = event
            super.init(tracker: tracker, completion: completion)
        }
        
        override func execute() {
            self.tracker?.preTrackActions { [weak self] (error) in
                if let err = error {
                    if let c = self?.completion {
                        c(err)
                    }
                    self?.finish()
                } else {
                    if let strongSelf = self {
                        strongSelf.tracker?.store.storeEvent(event: strongSelf.event, completion: { [weak self] (error) in
                            if let c = self?.completion {
                                c(error)
                            }
                            self?.finish()
                        })
                    }
                }
            }
        }
    }
    
    private class FlushOperation : AsyncBlockOperation {
        override func execute() {
            self.tracker?.flushStore { [weak self] (error) in
                if let c = self?.completion {
                    c(error)
                }
                self?.finish()
            }
        }
    }
    
    private class ClearOperation : AsyncBlockOperation {
        override func execute() {
            self.tracker?.clearStore { [weak self] (error) in
                if let c = self?.completion {
                    c(error)
                }
                self?.finish()
            }
        }
    }
}
