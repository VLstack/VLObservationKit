import CoreData
import Foundation
import Observation

extension VLEventsObservation
{
 /// Follows the CloudKit imports (NSPersistentCloudKitContainer, also used by SwiftData)
 // NOTE: offline, an import already started stays open until the network comes back, and no event is sent at all, not even the setup (measured 2026-10-19)
 @MainActor
 @Observable
 public final class CloudKitImportObserver
 {
  /// True while at least one import is running, and for a short delay after the last one ends
  public private(set) var isImporting: Bool = false

  /// True once the first import since launch has ended, whatever its outcome, or once the setup has failed (no import follows); never goes back to false
  public private(set) var hasCompletedFirstImport: Bool = false

  /// Delay before isImporting goes back to false: absorbs the imports that follow each other
  @ObservationIgnored
  internal var idleDelay: Duration = .milliseconds(500)

  @ObservationIgnored
  private var importsInProgress: Set<UUID> = []

  @ObservationIgnored
  private var notificationObserver: (any NSObjectProtocol)? = nil

  @ObservationIgnored
  private var idleTask: Task<Void, Never>? = nil

  public init() {}

  /// To call only once, for the whole life of the app
  public func start()
  {
   guard notificationObserver == nil else { return }

   // NOTE: main queue, so that starts and ends are handled in the order they are sent
   notificationObserver = NotificationCenter.default.addObserver(forName: NSPersistentCloudKitContainer.eventChangedNotification,
                                                                 object: nil,
                                                                 queue: .main)
   {
    [weak self] notification in
    guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey] as? NSPersistentCloudKitContainer.Event
    else { return }

    let identifier = event.identifier
    let isEnd = event.endDate != nil
    let succeeded = event.succeeded
    switch event.type
    {
     case .setup:
      guard isEnd else { return }
      MainActor.assumeIsolated
      {
       self?.handleSetupEnd(succeeded: succeeded)
      }

     case .import:
      MainActor.assumeIsolated
      {
       self?.handleImport(identifier: identifier, isEnd: isEnd)
      }

     case .export:
      break

     @unknown default:
      break
    }
   }
  }

  internal func handleImport(identifier: UUID,
                             isEnd: Bool)
  {
   if isEnd
   {
    importsInProgress.remove(identifier)
    if !hasCompletedFirstImport { hasCompletedFirstImport = true }
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

   // End without a known start: nothing was in progress
   guard isImporting else { return }

   idleTask = Task
   {
    try? await Task.sleep(for: idleDelay)
    guard !Task.isCancelled else { return }
    isImporting = false
   }
  }

  // NOTE: a failed setup (presumably no iCloud account, not measured yet) is not followed by any import
  internal func handleSetupEnd(succeeded: Bool)
  {
   guard !succeeded,
         !hasCompletedFirstImport
   else { return }

   hasCompletedFirstImport = true
  }
 }
}
