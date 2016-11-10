//
//  EventTrackerTests.swift
//  EventTrackerTests
//
//  Created by Billy Irwin on 11/9/16.
//  Copyright © 2016 because. All rights reserved.
//

import XCTest
import EventTracker

class TestEvent : Event {
    func toString() -> String {
        return "event"
    }
}

class EventTrackerTests: XCTestCase {
    
    var tracker: EventTracker!
    var store: EventStore!
    
    override func setUp() {
        super.setUp()
        self.store = TestEventStore()
        let config = EventTrackerConfiguration(store: self.store, uploader: TestEventTrackerUploader(), flushPolicy: .Manual)
        self.tracker = EventTracker(configuration: config)
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testTrackingSingleEvent() {
        self.tracker.trackEvent(event: TestEvent())
        XCTAssert(store.allEvents().count == 1)
    }
    
    func testFlushing() {
        self.tracker.trackEvent(event: TestEvent())
        self.tracker.flushEvents()
        XCTAssert(store.allEvents().count == 0)
    }
    
    func testLimitFlushingPolicy() {
        let config = EventTrackerConfiguration(store: self.store, uploader: TestEventTrackerUploader(), flushPolicy: .EventLimit(limit: 2))
        self.tracker = EventTracker(configuration: config)
        self.tracker.trackEvent(event: TestEvent())
        self.tracker.trackEvent(event: TestEvent())
        self.tracker.trackEvent(event: TestEvent())
        XCTAssert(store.allEvents().count == 1)
    }
    
}
