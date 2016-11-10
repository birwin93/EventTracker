//
//  EventTrackerUploader.swift
//  EventTracker
//
//  Created by Billy Irwin on 11/9/16.
//  Copyright © 2016 becauseinc. All rights reserved.
//

import Foundation

public protocol EventTrackerUploader {
    func uploadEvents(events: [Event])
}

public class Tracker: EventTrackerUploader {
    
    public func uploadEvents(events: [Event]) {
        for event in events {
            print(event.toString())
        }
    }
    
}
