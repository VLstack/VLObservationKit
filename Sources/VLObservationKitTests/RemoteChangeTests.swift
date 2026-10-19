import Testing
@testable import VLObservationKit

private let app = "fr.vlstack.Yumeo-dev"
private let widget = "fr.vlstack.Logeo.widget"
private let cloudKitImport = "NSCloudKitMirroringDelegate.import"

@Test("App write without author: local")
func appWriteIsLocal()
{
 #expect(TestRemoteChangeObserver.isLocal(author: nil, transactionBundleIdentifier: app, appBundleIdentifier: app))
}

@Test("CloudKit import: remote")
func cloudKitImportIsRemote()
{
 #expect(!TestRemoteChangeObserver.isLocal(author: cloudKitImport, transactionBundleIdentifier: app, appBundleIdentifier: app))
}

@Test("Other bundle without author (widget): remote")
func otherBundleIsRemote()
{
 #expect(!TestRemoteChangeObserver.isLocal(author: nil, transactionBundleIdentifier: widget, appBundleIdentifier: app))
}
