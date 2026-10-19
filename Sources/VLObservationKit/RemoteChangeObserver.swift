import CoreData
import Foundation
import os
import SwiftData

extension VLEventsObservation
{
 // Lit l'historique SwiftData à chaque changement distant du magasin et envoie les événements traduits par l'app
 public final actor RemoteChangeObserver<EVENT: VLEventsObservation.ObservableEvent, PROPERTY: VLEventsObservation.ObservableProperty>
 {
  public typealias Translate = @Sendable (VLEventsObservation.RemoteChange) -> VLEventsObservation.Payload<EVENT, PROPERTY>?

  private let modelContainer: ModelContainer
  private let translate: Translate
  private let notifier = VLEventsObservation.Notifier<EVENT, PROPERTY>()
  private let bundleIdentifier: String? = Bundle.main.bundleIdentifier
  private let logger = Logger(subsystem: "fr.vlstack.VLObservationKit", category: "RemoteChangeObserver")

  private var startDate: Date = .now
  private var lastToken: DefaultHistoryToken? = nil
  private var notificationObserver: (any NSObjectProtocol)? = nil
  private var debounceTask: Task<Void, Never>? = nil

  public init(modelContainer: ModelContainer,
              translate: @escaping Translate)
  {
   self.modelContainer = modelContainer
   self.translate = translate
  }

  public func start()
  {
   guard notificationObserver == nil else { return }

   // NOTE: les vues chargent déjà tout au démarrage, l'historique n'est lu qu'à partir de maintenant
   startDate = .now
   notificationObserver = NotificationCenter.default.addObserver(forName: .NSPersistentStoreRemoteChange,
                                                                 object: nil,
                                                                 queue: nil)
   {
    [weak self] _ in
    Task { await self?.scheduleRead() }
   }
  }

  // Une synchro envoie une rafale de notifications : une seule lecture une seconde après la dernière
  private func scheduleRead()
  {
   debounceTask?.cancel()
   debounceTask = Task
   {
    try? await Task.sleep(for: .seconds(1))
    guard !Task.isCancelled else { return }
    await readHistory()
   }
  }

  // Ecriture de l'app elle-même : déjà signalée par ses ModelManager
  private func isLocal(_ transaction: DefaultHistoryTransaction) -> Bool
  {
   Self.isLocal(author: transaction.author,
                transactionBundleIdentifier: transaction.bundleIdentifier,
                appBundleIdentifier: bundleIdentifier)
  }

  // Un import CloudKit porte l'auteur "NSCloudKitMirroringDelegate.import", un widget écrit depuis un autre bundle
  internal static func isLocal(author: String?,
                               transactionBundleIdentifier: String,
                               appBundleIdentifier: String?) -> Bool
  {
   author == nil && transactionBundleIdentifier == appBundleIdentifier
  }

  private func readHistory() async
  {
   var descriptor = HistoryDescriptor<DefaultHistoryTransaction>()
   if let lastToken
   {
    descriptor.predicate = #Predicate { $0.token > lastToken }
   }
   else
   {
    let startDate = self.startDate
    descriptor.predicate = #Predicate { $0.timestamp > startDate }
   }

   let transactions: [ DefaultHistoryTransaction ]
   do
   {
    transactions = try ModelContext(modelContainer).fetchHistory(descriptor)
   }
   catch
   {
    // NOTE: jeton expiré ou lecture impossible : on repart de maintenant, les changements manqués ne seront pas envoyés
    logger.error("Lecture de l'historique impossible : \(error.localizedDescription, privacy: .public)")
    lastToken = nil
    startDate = .now
    return
   }

   guard let lastTransaction = transactions.last else { return }
   lastToken = lastTransaction.token

   var payloads: [ VLEventsObservation.Payload<EVENT, PROPERTY> ] = []
   for transaction in transactions where !isLocal(transaction)
   {
    for change in transaction.changes
    {
     let remoteChange: VLEventsObservation.RemoteChange
     switch change
     {
      case .insert(let insert): remoteChange = .init(kind: .insert, persistentIdentifier: insert.changedPersistentIdentifier)
      case .update(let update): remoteChange = .init(kind: .update, persistentIdentifier: update.changedPersistentIdentifier)
      case .delete(let delete): remoteChange = .init(kind: .delete, persistentIdentifier: delete.changedPersistentIdentifier)
      @unknown default: continue
     }

     if let payload = translate(remoteChange)
     {
      payloads.append(payload)
     }
    }
   }

   guard !payloads.isEmpty else { return }
   await notifier.dispatch(payloads)
  }
 }
}
