import Foundation

extension VLEventsObservation
{
 public final actor Notifier<EVENT: VLEventsObservation.ObservableEvent, PROPERTY: VLEventsObservation.ObservableProperty>
 {
  public init() {}

  internal func resolve(event: EVENT,
                       property: PROPERTY?,
                       seen: inout Set<EVENT>) async -> [ VLEventsObservation.Payload<EVENT, PROPERTY> ]
  {
   guard seen.insert(event).inserted else { return [] }

   var result: [ VLEventsObservation.Payload<EVENT, PROPERTY> ] = []
   result.append(.init(event: event, property: property))

   if property?.allowRelatedPropagation == false
   {
    return result
   }

   for relatedEvent in event.relatedEvents
   {
    let toAdd = await resolve(event: relatedEvent,
                              property: nil,
                              seen: &seen)
    result.append(contentsOf: toAdd)
   }

   return result
  }

  // Envoi groupé : un événement atteint par plusieurs payloads (par exemple .recipes) n'est envoyé qu'une fois
  internal func resolve(_ payloads: [ VLEventsObservation.Payload<EVENT, PROPERTY> ]) async -> [ VLEventsObservation.Payload<EVENT, PROPERTY> ]
  {
   var seen: Set<EVENT> = []
   var resolved: [ VLEventsObservation.Payload<EVENT, PROPERTY> ] = []
   for payload in payloads
   {
    let toAdd = await resolve(event: payload.event,
                              property: payload.property,
                              seen: &seen)
    resolved.append(contentsOf: toAdd)
   }

   return resolved
  }

  public func dispatch(_ event: EVENT,
                       _ property: PROPERTY?) async
  {
   await dispatch([ .init(event: event, property: property) ])
  }

  public func dispatch(_ payloads: [ VLEventsObservation.Payload<EVENT, PROPERTY> ]) async
  {
   let resolved = await resolve(payloads)

   await MainActor.run
   {
    for payload in resolved
    {
     NotificationCenter.default.post(name: VLEventsObservation.Notifications.observable.name,
                                     object: nil,
                                     userInfo: [ "payload": payload ])
    }
   }
  }
 }
}
