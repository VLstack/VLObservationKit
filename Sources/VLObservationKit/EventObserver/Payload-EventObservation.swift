import VLstackNamespace

extension VLstack.EventsObservation
{
 public struct Payload<EVENT: VLstack.EventsObservation.ObservableEvent, PROPERTY: VLstack.EventsObservation.ObservableProperty>: Sendable
 {
  public let event: EVENT
  public let property: PROPERTY?

  public init(event: EVENT,
               property: PROPERTY?)
  {
   self.event = event
   self.property = property
  }
 }
}
