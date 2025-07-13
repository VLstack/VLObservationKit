import VLstackNamespace

extension VLstack.EventsObservation
{
 public protocol ObservableEvent: Identifiable, Equatable, Hashable, Sendable where ID == String
 {
  var affectsModelContext: Bool { get }
  var relatedEvents: Set<Self> { get }
 }

 public protocol ObservableProperty: Identifiable, Equatable, Hashable, Sendable
 {
 }
}
