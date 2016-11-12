//
//  EventStore.swift
//  EventLogger
//
//  Created by Billy Irwin on 11/9/16.
//  Copyright © 2016 becauseinc. All rights reserved.
//

import Foundation

public protocol EventStore {
    func storeEvent(event: Event) throws
    func allEvents() throws -> [Event]
    func deleteEvents() throws
}

public class InMemoryEventStore : EventStore {
    
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

enum FileEventStoreError: Error {
    case fileNotFound
    case couldNotWrite
    case couldNotRead
    case couldNotDelete
}

public class FileEventStore : EventStore {
    
    private let fileName: String
    static let defaultFileName = "tracked_events.txt"
    
    private let batchSize: Int
    static let defaultBatchSize = 100
    
    private var currentBatchIndex = 0
    private var batchCache = [Event]()
    
    convenience init() {
        self.init(fileName: FileEventStore.defaultFileName, batchSize: FileEventStore.defaultBatchSize)
    }
    
    convenience init(batchSize: Int) {
        self.init(fileName: FileEventStore.defaultFileName, batchSize: batchSize)
    }
    
    init(fileName: String, batchSize: Int) {
        self.fileName = fileName
        self.batchSize = batchSize
    }
    
    public func storeEvent(event: Event) throws {
        self.batchCache.append(event)
        if self.batchCache.count > self.batchSize {
            try self.writeBatchToFile()
        }
    }
    
    public func allEvents() throws -> [Event] {
        var events = [Event]()
        if self.currentBatchIndex > 0 {
            for index in 0...self.currentBatchIndex-1 {
                let path = try getFilePath(batchIndex: index)
                guard let batchEvents = NSKeyedUnarchiver.unarchiveObject(withFile: path) as? [Event] else  {
                    throw FileEventStoreError.couldNotRead
                }
                events.append(contentsOf: batchEvents)
            }
        }
        events.append(contentsOf: self.batchCache)
        return events
    }
    
    public func deleteEvents() throws {
        if self.currentBatchIndex > 0 {
            for index in 0...self.currentBatchIndex-1 {
                let path = try getFilePath(batchIndex: index)
                do {
                    try FileManager.default.removeItem(atPath: path)
                } catch {
                    throw FileEventStoreError.couldNotDelete
                }
            }
        }
        self.batchCache.removeAll()
        self.currentBatchIndex = 0
    }
    
    // MARK: Private
    
    // Fetch the stored event file, create it if it doesn't exist
    private func getFilePath(batchIndex: Int) throws -> String {
        if let path =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fullPath = path.appendingPathComponent(String(batchIndex) + "_" + self.fileName).path
            if !FileManager.default.fileExists(atPath: fullPath) {
                FileManager.default.createFile(atPath: fullPath, contents: nil, attributes: nil)
            }
            return fullPath
        } else {
            throw FileEventStoreError.fileNotFound
        }
    }
    
    // Write current batch to file, then delete cached events and increment batch counter
    private func writeBatchToFile() throws {
        let path = try getFilePath(batchIndex: self.currentBatchIndex)
        NSKeyedArchiver.archiveRootObject(self.batchCache, toFile: path)
        
        self.batchCache.removeAll()
        self.currentBatchIndex+=1
    }

}
