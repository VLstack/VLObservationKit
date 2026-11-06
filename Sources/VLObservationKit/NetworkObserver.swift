import Foundation
import Network
import Observation

extension VLEventsObservation
{
 /// Follows the network availability (NWPathMonitor)
 // NOTE: a satisfied path does not prove that a given server answers (hotel Wi-Fi not signed in yet, for example)
 @MainActor
 @Observable
 public final class NetworkObserver
 {
  /// True when a network path is available; true until the system sends the first path
  public private(set) var isConnected: Bool = true

  @ObservationIgnored
  private var monitor: NWPathMonitor? = nil

  public init() {}

  /// To call only once, for the whole life of the app
  public func start()
  {
   guard monitor == nil else { return }

   let monitor = NWPathMonitor()
   monitor.pathUpdateHandler =
   {
    [weak self] path in
    let isSatisfied = path.status == .satisfied
    MainActor.assumeIsolated
    {
     self?.handlePathUpdate(isSatisfied: isSatisfied)
    }
   }

   // NOTE: main queue, so that the observable state is updated on the main actor
   monitor.start(queue: .main)
   self.monitor = monitor
  }

  internal func handlePathUpdate(isSatisfied: Bool)
  {
   guard isConnected != isSatisfied else { return }

   isConnected = isSatisfied
  }
 }
}
