import GraniteAgents

/// The tour agent's place in Granite's roster: an app that links this package finds the `tour` agent by this record,
/// with nothing listed by hand.
@used @section("__DATA_CONST,__granite")
let tourRecord: GraniteRoster.Record = { GraniteRoster.record(TourAgent.self) }
