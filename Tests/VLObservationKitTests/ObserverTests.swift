import Combine
import Foundation
import Testing
@testable import VLObservationKit

// NOTE: goes through the global NotificationCenter, the tests of this suite must not run in parallel
@Suite("Notifier to Observer", .serialized)
@MainActor
struct ObserverTests
{
 @Test("A dispatched event reaches the listener of a related event")
 func dispatchReachesListener() async
 {
  let observer = TestObserver()
  var received: [ TestProperty? ] = []
  let cancellable = observer.listen(.b).sink { received.append($0) }

  await TestNotifier().dispatch(.a, .propagate)

  #expect(received == [ nil ])
  cancellable.cancel()
 }

 @Test("Batch dispatch: the shared related event is received once")
 func batchReachesListenerOnce() async
 {
  let observer = TestObserver()
  var received: [ TestProperty? ] = []
  let cancellable = observer.listen(.c).sink { received.append($0) }

  await TestNotifier().dispatch([ .init(event: .a, property: .propagate),
                                  .init(event: .d, property: .propagate) ])

  #expect(received == [ nil ])
  cancellable.cancel()
 }

 @Test("The listener of the initial event receives its property, related events are not sent when propagation is forbidden")
 func propertyReachesListener() async
 {
  let observer = TestObserver()
  var receivedA: [ TestProperty? ] = []
  var receivedB: [ TestProperty? ] = []
  let cancellableA = observer.listen(.a).sink { receivedA.append($0) }
  let cancellableB = observer.listen(.b).sink { receivedB.append($0) }

  await TestNotifier().dispatch(.a, .stop)

  #expect(receivedA == [ .stop ])
  #expect(receivedB.isEmpty)
  cancellableA.cancel()
  cancellableB.cancel()
 }

 @Test("Listening to the same event twice gives the same subject")
 func sameEventSameSubject()
 {
  let observer = TestObserver()
  #expect(observer.getPublisher(.a) === observer.getPublisher(.a))
  #expect(observer.getPublisher(.a) !== observer.getPublisher(.b))
 }

 @Test("Listening to nil gives a finished publisher")
 func nilEventIsFinished()
 {
  let observer = TestObserver()
  var finished = false
  var received: [ TestProperty? ] = []
  let cancellable = observer.listen(nil).sink(receiveCompletion: { finished = $0 == .finished },
                                              receiveValue: { received.append($0) })

  #expect(finished)
  #expect(received.isEmpty)
  cancellable.cancel()
 }

 @Test("Releasing the observer finishes its publishers")
 func deinitFinishesPublishers()
 {
  var observer: TestObserver? = TestObserver()
  var finished = false
  let cancellable = observer?.listen(.a).sink(receiveCompletion: { finished = $0 == .finished },
                                              receiveValue: { _ in })

  observer = nil

  #expect(finished)
  cancellable?.cancel()
 }

 @Test("A notification without a valid payload is ignored")
 func invalidPayloadIsIgnored()
 {
  let observer = TestObserver()
  var received: [ TestProperty? ] = []
  let cancellable = observer.listen(.a).sink { received.append($0) }

  NotificationCenter.default.post(name: VLEventsObservation.Notifications.observable.name,
                                  object: nil,
                                  userInfo: [ "payload": "not a payload" ])
  NotificationCenter.default.post(name: VLEventsObservation.Notifications.observable.name,
                                  object: nil,
                                  userInfo: nil)

  #expect(received.isEmpty)
  cancellable.cancel()
 }
}
