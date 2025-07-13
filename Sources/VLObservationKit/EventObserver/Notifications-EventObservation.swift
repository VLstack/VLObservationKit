import VLstackNamespace
import Foundation
import CoreData

extension VLstack.EventsObservation
{
 internal enum Notifications: String
 {
  case context
  case cloudKit
  case observable

  internal var name: Notification.Name
  {
   switch self
   {
    case .context: Notification.Name("fr.vlstack.VLObservationKit.EventsObservation.context")
    case .cloudKit: NSPersistentCloudKitContainer.eventChangedNotification
    case .observable: Notification.Name("fr.vlstack.VLObservationKit.EventsObservation.observable")
   }
  }
 }
}
