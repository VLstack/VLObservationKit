import Testing
@testable import VLObservationKit

@Suite("Network observer")
@MainActor
struct NetworkObserverTests
{
 @Test("isConnected is true before the first path")
 func connectedAtStart()
 {
  let observer = VLEventsObservation.NetworkObserver()
  #expect(observer.isConnected)
 }

 @Test("An unsatisfied path clears isConnected")
 func unsatisfiedPathClears()
 {
  let observer = VLEventsObservation.NetworkObserver()
  observer.handlePathUpdate(isSatisfied: false)
  #expect(!observer.isConnected)
 }

 @Test("A satisfied path after an unsatisfied one sets isConnected again")
 func satisfiedPathSetsAgain()
 {
  let observer = VLEventsObservation.NetworkObserver()
  observer.handlePathUpdate(isSatisfied: false)
  observer.handlePathUpdate(isSatisfied: true)
  #expect(observer.isConnected)
 }
}
