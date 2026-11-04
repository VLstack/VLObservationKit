@testable import VLObservationKit

// Test graph: a → b → c → a (cycle), d → c; one related event per case to keep a fixed order
enum TestEvent: VLEventsObservation.ObservableEvent
{
 case a
 case b
 case c
 case d

 var id: String { String(describing: self) }

 var relatedEvents: Set<TestEvent>
 {
  switch self
  {
   case .a: [ .b ]
   case .b: [ .c ]
   case .c: [ .a ]
   case .d: [ .c ]
  }
 }
}

enum TestProperty: VLEventsObservation.ObservableProperty
{
 case propagate
 case stop

 var id: String { String(describing: self) }

 var allowRelatedPropagation: Bool { self == .propagate }
}

typealias TestNotifier = VLEventsObservation.Notifier<TestEvent, TestProperty>
typealias TestObserver = VLEventsObservation.Observer<TestEvent, TestProperty>
typealias TestRemoteChangeObserver = VLEventsObservation.RemoteChangeObserver<TestEvent, TestProperty>
