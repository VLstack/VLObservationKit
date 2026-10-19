import Combine
import Testing
@testable import VLObservationKit

// NOTE: passe par le NotificationCenter global, les tests de cette suite ne doivent pas tourner en parallèle
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
}
