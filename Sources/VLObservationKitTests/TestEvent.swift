@testable import VLObservationKit

// Graphe de test : a → b → c → a (cycle), d → c ; un seul événement lié par cas pour garder un ordre fixe
enum TestEvent: VLEventsObservation.ObservableEvent
{
 case a
 case b
 case c
 case d

 var id: String { String(describing: self) }

 var affectsModelContext: Bool { true }

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
