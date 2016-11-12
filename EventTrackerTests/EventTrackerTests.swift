//
//  EventTrackerTests.swift
//  EventTrackerTests
//
//  Created by Billy Irwin on 11/9/16.
//  Copyright © 2016 because. All rights reserved.
//

import XCTest
import EventTracker

class TestEvent : NSObject, Event {
    
    let content: String
    
    override init() {
        self.content = "event"
        super.init()
    }
    
    init(content: String) {
        self.content = content
    }
    
    func toString() -> String {
        return self.content
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.content, forKey: "content")
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let content = aDecoder.decodeObject(forKey: "content") as? String else { return nil }
        self.init(content: content)
    }
}

class BaseEventTrackerTests : XCTestCase {
    
    var tracker: EventTracker!
    var store: EventStore!
    
    override func setUp() {
        super.setUp()
        self.store = InMemoryEventStore()
        let config = EventTrackerConfiguration(store: store, uploader: TestEventTrackerUploader(), flushPolicy: .Manual)
        self.tracker = EventTracker(configuration: config)
    }
    
    func testTrackingSingleEvent() {
        try! self.tracker.trackEvent(event: TestEvent())
        XCTAssertEqual(try! self.store.allEvents().count, 1)
    }
    
    func testFlushing() {
        try! self.tracker.trackEvent(event: TestEvent())
        try! self.tracker.flushEvents()
        XCTAssertEqual(try! self.store.allEvents().count, 0)
    }
    
    func testLimitFlushingPolicy() {
        let config = EventTrackerConfiguration(store: store, uploader: TestEventTrackerUploader(), flushPolicy: .EventLimit(limit: 2))
        let newTracker = EventTracker(configuration: config)
        try! newTracker.trackEvent(event: TestEvent())
        try! newTracker.trackEvent(event: TestEvent())
        try! newTracker.trackEvent(event: TestEvent())
        XCTAssertEqual(try! self.store.allEvents().count, 1)
    }
    
}

class FileEventTracker : BaseEventTrackerTests {
    
    override func setUp() {
        super.setUp()
        self.tracker = self.trackerWithBatchSize(batchSize: 2)
    }
    
    func testWritingMultipleFileBatches() {
        self.tracker = self.trackerWithBatchSize(batchSize: 2)
        
        for _ in 0...7 {
            try! self.tracker.trackEvent(event: TestEvent())
        }
        
        XCTAssertEqual(try! self.store.allEvents().count, 8)
        
    }
    
    func testWritingMultipleFileBatchesWithFlushes() {
        self.tracker = self.trackerWithBatchSize(batchSize: 2)
        
        for _ in 0...7 {
            try! self.tracker.trackEvent(event: TestEvent())
        }
        
        try! self.tracker.flushEvents()
        
        for _ in 0...5 {
            try! self.tracker.trackEvent(event: TestEvent())
        }
        
        XCTAssertEqual(try! self.store.allEvents().count, 6)
    }
    
    // MARK: Private
    
    func trackerWithBatchSize(batchSize: Int) -> EventTracker {
        self.store = FileEventStore(batchSize: batchSize)
        let config = EventTrackerConfiguration(store: store, uploader: TestEventTrackerUploader(), flushPolicy: .Manual)
        return EventTracker(configuration: config)
    }
}
