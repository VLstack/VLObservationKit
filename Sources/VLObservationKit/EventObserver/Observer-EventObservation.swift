import VLstackNamespace
import Observation
import SwiftData
import CoreData
import Combine

extension VLstack.EventsObservation
{
 @Observable
 public final class Observer<EVENT: VLstack.EventsObservation.ObservableEvent, PROPERTY: VLstack.EventsObservation.ObservableProperty>
 {
  private(set) var modelContextHasChanged: String = ""
  private(set) var cloudKitHasChanged: String = ""

  @ObservationIgnored
  internal var subjects: [ String : PassthroughSubject<PROPERTY, Never> ] = [:]

  @ObservationIgnored
  internal var globalSubject = PassthroughSubject<VLstack.EventsObservation.Notifications, Never>()

  @ObservationIgnored
  internal var cancellables = Set<AnyCancellable>()

  @ObservationIgnored
  internal let debounceQueue = DispatchQueue(label: "fr.vlstack.VLObservationKit.EventsObservation.debouncedQueue",
                                            qos: .userInitiated)

  public init()
  {
   setupDebouncedUpdates()

   NotificationCenter.default.addObserver(self,
                                          selector: #selector(onCloudKit(notification:)),
                                          name: VLstack.EventsObservation.Notifications.cloudKit.name,
                                          object: nil)

   NotificationCenter.default.addObserver(self,
                                          selector: #selector(onContext(notification:)),
                                          name: VLstack.EventsObservation.Notifications.context.name,
                                          object: nil)

   NotificationCenter.default.addObserver(self,
                                          selector: #selector(onObservable(notification:)),
                                          name: VLstack.EventsObservation.Notifications.observable.name,
                                          object: nil)
  }

  deinit
  {
   NotificationCenter.default.removeObserver(self)

   for (_, subject) in subjects
   {
    subject.send(completion: .finished)
   }
   subjects.removeAll()
   globalSubject.send(completion: .finished)
   cancellables.removeAll()
  }

  internal func getPublisher(_ event: EVENT?) -> PassthroughSubject<PROPERTY, Never>
  {
   guard let event
   else
   {
    let subject = PassthroughSubject<PROPERTY, Never>()
    subject.send(completion: .finished)
    return subject
   }

   let identifier = event.id

   if let subject = subjects[identifier]
   {
    return subject
   }

   let subject = PassthroughSubject<PROPERTY, Never>()
   subjects[identifier] = subject

   return subject
  }

  public func listen(_ event: EVENT?) -> AnyPublisher<PROPERTY, Never>
  {
   getPublisher(event).eraseToAnyPublisher()
  }

  internal func setupDebouncedUpdates()
  {
   globalSubject
    .collect(.byTime(self.debounceQueue, .milliseconds(50)))
    .receive(on: DispatchQueue.main)
    .sink
    {
     [weak self] changes in
     guard let self else { return }

     let uuid = UUID().uuidString
     let set = Set(changes)

     if set.contains(.context) { self.modelContextHasChanged = uuid }
     if set.contains(.cloudKit) { self.cloudKitHasChanged = uuid }
    }
    .store(in: &cancellables)
  }

  @objc
  internal func onCloudKit(notification: Notification)
  {
   self.globalSubject.send(.cloudKit)
  }

  @objc
  internal func onContext(notification: Notification)
  {
   self.globalSubject.send(.context)
  }

  @objc
  internal func onObservable(notification: Notification)
  {
   guard let payload = notification.userInfo?["payload"] as? VLstack.EventsObservation.Payload<EVENT, PROPERTY>
   else { return }

   getPublisher(payload.event).send(payload.property)
  }
 }
}
