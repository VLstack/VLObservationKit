import Testing
@testable import VLObservationKit

@Test("Initial event keeps its property, related events get nil")
func relatedEventsGetNil() async
{
 let resolved = await TestNotifier().resolve([ .init(event: .a, property: .propagate) ])
 #expect(resolved.map(\.event) == [ .a, .b, .c ])
 #expect(resolved.map(\.property) == [ .propagate, nil, nil ])
}

@Test("Nil property propagates")
func nilPropertyPropagates() async
{
 let resolved = await TestNotifier().resolve([ .init(event: .a, property: nil) ])
 #expect(resolved.map(\.event) == [ .a, .b, .c ])
}

@Test("Property that forbids propagation: initial event only")
func stopPropertyDoesNotPropagate() async
{
 let resolved = await TestNotifier().resolve([ .init(event: .a, property: .stop) ])
 #expect(resolved.map(\.event) == [ .a ])
}

@Test("A cycle does not loop")
func cycleStops() async
{
 let resolved = await TestNotifier().resolve([ .init(event: .c, property: .propagate) ])
 #expect(resolved.map(\.event) == [ .c, .a, .b ])
}

@Test("A chain of related events is followed to the end")
func chainIsFollowed() async
{
 let resolved = await TestNotifier().resolve([ .init(event: .d, property: .propagate) ])
 #expect(resolved.map(\.event) == [ .d, .c, .a, .b ])
}

@Test("Batch: a related event shared by two payloads is sent once")
func batchSendsSharedEventOnce() async
{
 let resolved = await TestNotifier().resolve([ .init(event: .a, property: .propagate),
                                               .init(event: .d, property: .propagate) ])
 #expect(resolved.map(\.event) == [ .a, .b, .c, .d ])
}

@Test("Batch: same event twice, only the first payload is kept")
func batchKeepsFirstPayload() async
{
 let resolved = await TestNotifier().resolve([ .init(event: .a, property: .propagate),
                                               .init(event: .a, property: .stop) ])
 #expect(resolved.map(\.event) == [ .a, .b, .c ])
 #expect(resolved.first?.property == .propagate)
}

// NOTE: documents the current rule, the property of the second payload is lost
@Test("Batch: an event already reached as a related event keeps nil")
func batchRelatedEventKeepsNil() async
{
 let resolved = await TestNotifier().resolve([ .init(event: .a, property: .propagate),
                                               .init(event: .b, property: .stop) ])
 #expect(resolved.map(\.event) == [ .a, .b, .c ])
 #expect(resolved.map(\.property) == [ .propagate, nil, nil ])
}

@Test("Empty batch: nothing")
func emptyBatch() async
{
 let resolved = await TestNotifier().resolve([])
 #expect(resolved.isEmpty)
}
