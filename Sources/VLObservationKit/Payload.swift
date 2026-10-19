extension VLEventsObservation
{
 public struct Payload<EVENT: VLEventsObservation.ObservableEvent, PROPERTY: VLEventsObservation.ObservableProperty>: Sendable
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
