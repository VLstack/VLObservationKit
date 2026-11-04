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

// NOTE: documents the current rule, an app that names its own writes sees them as remote
@Test("App write with an author: remote")
func appWriteWithAuthorIsRemote()
{
 #expect(!TestRemoteChangeObserver.isLocal(author: "import", transactionBundleIdentifier: app, appBundleIdentifier: app))
}

@Test("Unknown app bundle: remote")
func unknownAppBundleIsRemote()
{
 #expect(!TestRemoteChangeObserver.isLocal(author: nil, transactionBundleIdentifier: app, appBundleIdentifier: nil))
}
