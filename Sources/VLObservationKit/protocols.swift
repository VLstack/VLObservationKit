extension VLEventsObservation
{
 public protocol ObservableEvent: Identifiable, Equatable, Hashable, Sendable where ID == String
 {
  var relatedEvents: Set<Self> { get }
 }

 public protocol ObservableProperty: Identifiable, Equatable, Hashable, Sendable
 {
  var allowRelatedPropagation: Bool { get }
 }
}
