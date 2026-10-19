import CoreData
import Foundation
import Observation

extension VLEventsObservation
{
 // Suit les imports CloudKit en cours (NSPersistentCloudKitContainer, utilisé aussi par SwiftData)
 // NOTE: hors ligne, un import commencé reste ouvert jusqu'au retour du réseau, et aucun import ne commence (mesuré le 2026-10-19)
 @MainActor
 @Observable
 public final class CloudKitImportObserver
 {
  public private(set) var isImporting: Bool = false

  // Délai avant de repasser à faux : absorbe les imports qui s'enchaînent
  @ObservationIgnored
  internal var idleDelay: Duration = .milliseconds(500)

  @ObservationIgnored
  private var importsInProgress: Set<UUID> = []

  @ObservationIgnored
  private var notificationObserver: (any NSObjectProtocol)? = nil

  @ObservationIgnored
  private var idleTask: Task<Void, Never>? = nil

  public init() {}

  // Un seul appel pour toute la durée de l'app
  public func start()
  {
   guard notificationObserver == nil else { return }

   // NOTE: file principale, pour traiter début et fin dans l'ordre d'envoi
   notificationObserver = NotificationCenter.default.addObserver(forName: NSPersistentCloudKitContainer.eventChangedNotification,
                                                                 object: nil,
                                                                 queue: .main)
   {
    [weak self] notification in
    guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey] as? NSPersistentCloudKitContainer.Event,
          event.type == .import
    else { return }

    let identifier = event.identifier
    let isEnd = event.endDate != nil
    MainActor.assumeIsolated
    {
     self?.handleImport(identifier: identifier, isEnd: isEnd)
    }
   }
  }

  internal func handleImport(identifier: UUID,
                             isEnd: Bool)
  {
   if isEnd
   {
    importsInProgress.remove(identifier)
   }
   else
   {
    importsInProgress.insert(identifier)
   }

   idleTask?.cancel()

   if !importsInProgress.isEmpty
   {
    if !isImporting { isImporting = true }
    return
   }

   // Fin sans début connu : rien n'était en cours
   guard isImporting else { return }

   idleTask = Task
   {
    try? await Task.sleep(for: idleDelay)
    guard !Task.isCancelled else { return }
    isImporting = false
   }
  }
 }
}
