// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(name: "VLObservationKit",
                      defaultLocalization: "en",
                      platforms: [ .macOS(.v14), .iOS(.v17) ],
                      products:
                      [
                       .library(name: "VLObservationKit",
                                targets: ["VLObservationKit"])
                      ],
                      dependencies:
                      [
                       .package(url: "https://github.com/VLstack/VLstackNamespace", from: "1.2.0")
                      ],
                      targets:
                      [
                       .target(name: "VLObservationKit",
                               dependencies: [ "VLstackNamespace" ])
                      ])
