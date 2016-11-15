//
//  EventStore.swift
//  EventLogger
//
//  Created by Billy Irwin on 11/9/16.
//  Copyright © 2016 becauseinc. All rights reserved.
//

import Foundation

public typealias EventStoreReturnCompletion = (([Event], Error?) -> Void)
public typealias EventStoreCompletion = ((Error?) -> Void)

public protocol EventStore {
    func storeEvent(event: Event, completion: @escaping EventStoreCompletion)
    func allEvents(completion: @escaping EventStoreReturnCompletion)
    func deleteEvents(completion: @escaping EventStoreCompletion)
}

public class InMemoryEventStore : EventStore {
    
    private var cache = [Event]()
    
    public func storeEvent(event: Event, completion: @escaping EventStoreCompletion) {
        self.cache.append(event)
        completion(nil)
    }
    
    public func allEvents(completion: @escaping  EventStoreReturnCompletion) {
        completion(self.cache, nil)
    }
    
    public func deleteEvents(completion: @escaping  EventStoreCompletion) {
        self.cache.removeAll()
        completion(nil)
    }
    
}

public enum FileEventStoreError: Error {
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
    
    public func storeEvent(event: Event, completion: @escaping EventStoreCompletion) {
        self.batchCache.append(event)
        if self.batchCache.count > self.batchSize {
            self.writeBatchToFile(completion: completion)
        } else {
            completion(nil)
        }
    }
    
    public func allEvents(completion: @escaping EventStoreReturnCompletion) {
        var events = [Event]()
        if self.currentBatchIndex > 0 {
            for index in 0...self.currentBatchIndex-1 {
                if let path = getFilePath(batchIndex: index) {
                    guard let batchEvents = NSKeyedUnarchiver.unarchiveObject(withFile: path) as? [Event] else {
                        completion([], FileEventStoreError.couldNotRead)
                        return
                    }
                    events.append(contentsOf: batchEvents)
                } else {
                    completion([], FileEventStoreError.fileNotFound)
                    return
                }
            }
        }
        events.append(contentsOf: self.batchCache)
        completion(events, nil)
    }
    
    public func deleteEvents(completion: @escaping EventStoreCompletion) {
        if self.currentBatchIndex > 0 {
            for index in 0...self.currentBatchIndex-1 {
                if let path = getFilePath(batchIndex: index) {
                    do {
                        try FileManager.default.removeItem(atPath: path)
                    } catch {
                        completion(FileEventStoreError.couldNotDelete)
                        return
                    }
                }
            }
        }
        self.batchCache.removeAll()
        self.currentBatchIndex = 0
        completion(nil)
    }
    
    // MARK: Private
    
    // Fetch the stored event file, create it if it doesn't exist
    private func getFilePath(batchIndex: Int) -> String? {
        if let path =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fullPath = path.appendingPathComponent(String(batchIndex) + "_" + self.fileName).path
            if !FileManager.default.fileExists(atPath: fullPath) {
                FileManager.default.createFile(atPath: fullPath, contents: nil, attributes: nil)
            }
            return fullPath
        }
        return nil
    }
    
    // Write current batch to file, then delete cached events and increment batch counter
    private func writeBatchToFile(completion: EventStoreCompletion) {
        if let path = getFilePath(batchIndex: self.currentBatchIndex) {
            NSKeyedArchiver.archiveRootObject(self.batchCache, toFile: path)
            self.batchCache.removeAll()
            self.currentBatchIndex+=1
            completion(nil)
        } else {
            completion(FileEventStoreError.fileNotFound)
        }
    }
}
