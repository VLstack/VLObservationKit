import Foundation
import Testing
@testable import VLObservationKit

@Suite("CloudKit import observer")
@MainActor
struct CloudKitImportObserverTests
{
 private func makeObserver() -> VLEventsObservation.CloudKitImportObserver
 {
  let observer = VLEventsObservation.CloudKitImportObserver()
  observer.idleDelay = .milliseconds(10)
  return observer
 }

 private func waitPastDelay() async throws
 {
  try await Task.sleep(for: .milliseconds(100))
 }

 @Test("An import start sets isImporting")
 func startSetsImporting()
 {
  let observer = makeObserver()
  observer.handleImport(identifier: UUID(), isEnd: false)
  #expect(observer.isImporting)
 }

 @Test("An import end clears isImporting after the delay, not before")
 func endClearsAfterDelay() async throws
 {
  let observer = makeObserver()
  let identifier = UUID()
  observer.handleImport(identifier: identifier, isEnd: false)
  observer.handleImport(identifier: identifier, isEnd: true)
  #expect(observer.isImporting)
  try await waitPastDelay()
  #expect(!observer.isImporting)
 }

 @Test("Overlapping imports: false only after the last end")
 func overlappingImports() async throws
 {
  let observer = makeObserver()
  let first = UUID()
  let second = UUID()
  observer.handleImport(identifier: first, isEnd: false)
  observer.handleImport(identifier: second, isEnd: false)
  observer.handleImport(identifier: first, isEnd: true)
  try await waitPastDelay()
  #expect(observer.isImporting)
  observer.handleImport(identifier: second, isEnd: true)
  try await waitPastDelay()
  #expect(!observer.isImporting)
 }

 @Test("An end without start changes nothing")
 func endWithoutStart() async throws
 {
  let observer = makeObserver()
  observer.handleImport(identifier: UUID(), isEnd: true)
  #expect(!observer.isImporting)
  try await waitPastDelay()
  #expect(!observer.isImporting)
 }

 @Test("A new import within the delay keeps isImporting")
 func chainedImports() async throws
 {
  let observer = makeObserver()
  let first = UUID()
  observer.handleImport(identifier: first, isEnd: false)
  observer.handleImport(identifier: first, isEnd: true)
  observer.handleImport(identifier: UUID(), isEnd: false)
  try await waitPastDelay()
  #expect(observer.isImporting)
 }

 @Test("The same import started twice ends with a single end")
 func sameImportStartedTwice() async throws
 {
  let observer = makeObserver()
  let identifier = UUID()
  observer.handleImport(identifier: identifier, isEnd: false)
  observer.handleImport(identifier: identifier, isEnd: false)
  observer.handleImport(identifier: identifier, isEnd: true)
  try await waitPastDelay()
  #expect(!observer.isImporting)
 }

 // MARK: - hasCompletedFirstImport

 @Test("hasCompletedFirstImport is false at start")
 func firstImportFalseAtStart()
 {
  let observer = makeObserver()
  #expect(!observer.hasCompletedFirstImport)
 }

 @Test("An import start alone keeps hasCompletedFirstImport false")
 func firstImportFalseWhileImporting() async throws
 {
  let observer = makeObserver()
  observer.handleImport(identifier: UUID(), isEnd: false)
  try await waitPastDelay()
  #expect(!observer.hasCompletedFirstImport)
 }

 @Test("An import end sets hasCompletedFirstImport at once, without the delay")
 func firstImportSetAtEnd()
 {
  let observer = makeObserver()
  let identifier = UUID()
  observer.handleImport(identifier: identifier, isEnd: false)
  observer.handleImport(identifier: identifier, isEnd: true)
  #expect(observer.hasCompletedFirstImport)
  #expect(observer.isImporting)
 }

 @Test("A failed setup sets hasCompletedFirstImport")
 func failedSetupSetsFirstImport()
 {
  let observer = makeObserver()
  observer.handleSetupEnd(succeeded: false)
  #expect(observer.hasCompletedFirstImport)
  #expect(!observer.isImporting)
 }

 @Test("A successful setup keeps hasCompletedFirstImport false")
 func successfulSetupKeepsFirstImport()
 {
  let observer = makeObserver()
  observer.handleSetupEnd(succeeded: true)
  #expect(!observer.hasCompletedFirstImport)
 }

 @Test("hasCompletedFirstImport never goes back to false")
 func firstImportStaysTrue() async throws
 {
  let observer = makeObserver()
  let first = UUID()
  observer.handleImport(identifier: first, isEnd: false)
  observer.handleImport(identifier: first, isEnd: true)
  observer.handleImport(identifier: UUID(), isEnd: false)
  observer.handleSetupEnd(succeeded: true)
  try await waitPastDelay()
  #expect(observer.hasCompletedFirstImport)
  #expect(observer.isImporting)
 }
}
