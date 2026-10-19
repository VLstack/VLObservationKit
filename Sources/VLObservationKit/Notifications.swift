import Foundation

extension VLEventsObservation
{
 internal enum Notifications: String
 {
  case observable

  internal var name: Notification.Name
  {
   switch self
   {
    case .observable: Notification.Name("fr.vlstack.VLObservationKit.EventsObservation.observable")
   }
  }
 }
}
