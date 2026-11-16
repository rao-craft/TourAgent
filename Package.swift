// swift-tools-version:6.0
// TourAgent: the first-run layer a new user meets (a welcome card over a scrim, then tips one at a time, per tab,
// remembered as done) and an "everything this app can do" pager of feature pages over a drifting gradient, as plain
// SwiftUI any app can use, written from the call's words, timings and look, as a Granite agent package. An app that
// links it finds the `tour` agent through Granite's roster, with nothing listed by hand.

import PackageDescription

let package = Package(
    name: "TourAgent",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "TourAgent", targets: ["TourAgent"]),
    ],
    dependencies: [
        .package(url: "https://github.com/riteshpakala/Granite.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "TourAgent",
            dependencies: [.product(name: "GraniteAgents", package: "Granite")],
            swiftSettings: [.swiftLanguageMode(.v6)]),
        .testTarget(
            name: "TourAgentTests",
            dependencies: ["TourAgent", .product(name: "GraniteAgents", package: "Granite")],
            swiftSettings: [.swiftLanguageMode(.v6)]),
    ]
)
