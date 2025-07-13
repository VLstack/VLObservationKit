import VLstackNamespace
import Foundation
import CoreData

extension VLstack.EventsObservation
{
 public final actor Notifier<EVENT: VLstack.EventsObservation.ObservableEvent, PROPERTY: VLstack.EventsObservation.ObservableProperty>
 {
  public init()
  {
  }

  internal func resolve(event: EVENT,
                       property: PROPERTY,
                       seen: inout Set<EVENT>) async -> [ VLstack.EventsObservation.Payload<EVENT, PROPERTY> ]
  {
   guard seen.insert(event).inserted else { return [] }

   var result: [ VLstack.EventsObservation.Payload<EVENT, PROPERTY> ] = []

   result.append(.init(event: event, property: property))
   for relatedEvent in event.relatedEvents
   {
    let toAdd = await resolve(event: relatedEvent,
                              property: property,
                              seen: &seen)
    result.append(contentsOf: toAdd)
   }

   return result
  }

  public func dispatch(_ event: EVENT,
                       _ property: PROPERTY) async
  {
   var seen: Set<EVENT> = []
   let resolved = await resolve(event: event,
                                property: property,
                                seen: &seen)
   await MainActor.run
   {
    var affectsModelContext: Bool = false
    for payload in resolved
    {
     NotificationCenter.default.post(name: VLstack.EventsObservation.Notifications.observable.name,
                                     object: nil,
                                     userInfo: [ "payload": payload ])
     affectsModelContext = affectsModelContext || payload.event.affectsModelContext
    }

    if affectsModelContext
    {
     NotificationCenter.default.post(name: VLstack.EventsObservation.Notifications.context.name,
                                     object: nil)
    }
   }
  }
 }
}
