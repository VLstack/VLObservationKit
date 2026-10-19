import Combine
import Foundation
import Observation

extension VLEventsObservation
{
 @Observable
 public final class Observer<EVENT: VLEventsObservation.ObservableEvent, PROPERTY: VLEventsObservation.ObservableProperty>
 {
  @ObservationIgnored
  internal var subjects: [ String : PassthroughSubject<PROPERTY?, Never> ] = [:]

  public init()
  {
   NotificationCenter.default.addObserver(self,
                                          selector: #selector(onObservable(notification:)),
                                          name: VLEventsObservation.Notifications.observable.name,
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
  }

  internal func getPublisher(_ event: EVENT?) -> PassthroughSubject<PROPERTY?, Never>
  {
   guard let event
   else
   {
    let subject = PassthroughSubject<PROPERTY?, Never>()
    subject.send(completion: .finished)

    return subject
   }

   let identifier = event.id

   if let subject = subjects[identifier]
   {
    return subject
   }

   let subject = PassthroughSubject<PROPERTY?, Never>()
   subjects[identifier] = subject

   return subject
  }

  public func listen(_ event: EVENT?) -> AnyPublisher<PROPERTY?, Never>
  {
   getPublisher(event).eraseToAnyPublisher()
  }

  @objc
  internal func onObservable(notification: Notification)
  {
   guard let payload = notification.userInfo?["payload"] as? VLEventsObservation.Payload<EVENT, PROPERTY>
   else { return }

   // Value of optional type 'PROPERTY?' must be unwrapped to a value of type 'PROPERTY'
   let property: PROPERTY? = payload.property
   let publisher: PassthroughSubject<PROPERTY?, Never> = getPublisher(payload.event)
   publisher.send(property)
  }
 }
}
