import SwiftData

extension VLEventsObservation
{
 // Un changement du magasin qui ne vient pas de l'app elle-même (import CloudKit, autre processus comme un widget)
 public struct RemoteChange: Sendable
 {
  public enum Kind: Sendable
  {
   case insert
   case update
   case delete
  }

  public let kind: Kind
  public let persistentIdentifier: PersistentIdentifier

  // Nom de la classe du modèle, par exemple "YMRecipe"
  public var entityName: String { persistentIdentifier.entityName }
 }
}
