// swift-tools-version: 6.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(name: "VLObservationKit",
                      defaultLocalization: "en",
                      platforms: [ .macOS(.v15), .iOS(.v18) ],
                      products:
                      [
                       .library(name: "VLObservationKit",
                                targets: ["VLObservationKit"])
                      ],
                      targets:
                      [
                       .target(name: "VLObservationKit"),
                       .testTarget(name: "VLObservationKitTests",
                                   dependencies: [ "VLObservationKit" ])
                      ])
