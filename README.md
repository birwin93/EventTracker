# EventTracker
A developer friendly framework for tracking, storing, and flushing events in iOS apps.

First define an Event to track
```swift
class UserImpressionEvent : NSObject, Event {

  let user: String

  init(user: String) {
    self.user = user
    super.init()
  }

  // All objects that conform to Event must implement toString()
  func toString() -> String {
    return "impression:" + self.user
  }

  // All objects that conform to Event must also conform to NSCoding
  func encode(with aCoder: NSCoder) {
    aCoder.encode(self.user, forKey: "user")
  }

  required convenience init?(coder aDecoder: NSCoder) {
    guard let user = aDecoder.decodeObject(forKey: "user") as? String else { return nil }
    self.init(user: user)
  }
}
```

Then create an EventTracker
```swift
// Create a file store to temporarily cache events before flushing
let store = FileEventStore()

// Create a simple flusher that will just log events to the console
// Could also create a flusher that uploads events for processing
let flusher = LogFlusher()

// Set the flush policy to flush after 100 events are tracked
let flushPolicy = EventFlushPolicy.EventLimit(limit: 100)

// Create the EventTracker
let configuration = EventTrackerConfiguration(store: store, flusher: flusher, flushPolicy: flushPolicy)
let tracker = EventTracker(configuration: configuration)
```

Then track
```swift
override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
  let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
  let user = self.users[indexPath.row]
  cell.render(user)

  // Track that the user was shown
  tracker.trackEvent(event: UserImpressionEvent(user: user))
  return cell
}
```

# Features

EventTracker was designed to give developers complete control over how events are defined, stored, and flushed.

### Event

```swift
@objc
public protocol Event: class, NSCoding {
  func toString() -> String
}
```
All tracked events must conform to the Event protocol. Event extends NSCoding to ensure that all events can be serialized/deserialized for storage.

### EventStore

```swift
public protocol EventStore {
  func storeEvent(event: Event, completion: @escaping EventStoreCompletion)
  func allEvents(completion: @escaping EventStoreReturnCompletion)
  func deleteEvents(completion: @escaping EventStoreCompletion)
}
```
Classes that conform to EventStore are used to temporarily cache tracked events before uploading them from the client. Events can be stored in whatever manner best suits the developer. The EventTracker currently comes with two concrete EventStore classes, InMemeoryEventStore and FileEventStore, which store events in memory and files, respectively. 

### EventFlusher

```swift
public protocol EventFlusher {
  func flushEvents(events: [Event], completion: @escaping EventFlushCompletion)
}
```
Class that conform to EventFlusher are responsible for emitting tracked events. EventFlushers can be used to log all recorded events, write them to a file, or most likely, upload all tracked events to a remote server. 

In addition, developers can define when to flush using an EventFlushPolicy. Possible options are:
- Manually call EventTracker.flushEvents()
- Flush after a set amount of events have been recorded
- Flush after a set amount of time

### EventTracker
```swift
public class EventTracker {
  public func trackEvent(event: Event, completion: EventTrackerCompletion?)
  public func flushEvents(completion: EventTrackerCompletion?)
  public func clearEvents(completion: EventTrackerCompletion?)
}
```

The EventTracker is used to drive storage and flushing of events. It is completely thread safe and ensures all operations are done serially.


# Installation

EventTracker requires Swift 3 and XCode 10

### CocoaPods
If you are unfamiliar with [CocoaPods](https://cocoapods.org/) please read these guides before proceeding:

* [Getting Started](https://guides.cocoapods.org/using/getting-started.html)    
* [Using CocoaPods](https://guides.cocoapods.org/using/using-cocoapods.html)

Add the following to your Podfile:

```ruby
use_frameworks!

pod 'EventTracker', '~>0.1.1'
```

### Manual

To install SQLite.swift as an Xcode sub-project:

1. Drag the **EventTracker.xcodeproj** file into your own project.
([Submodule][], clone, or [download][] the project first.)

2. In your target’s **General** tab, click the **+** button under **Linked
Frameworks and Libraries**.

3. Select the appropriate **EventTracker.framework** for your platform.


### Contact Info
Email: [birwin93@gmail.com](mailto:birwin93@gmail.com)

Twitter: [@billy_the_kid](https://twitter.com/billy_the_kid)

### Contributing
If you want to add functionality please open an issue and/or create a pull request.

### License
EventTracker is available under the MIT license. See the LICENSE file for more information.
