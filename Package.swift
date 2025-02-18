// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "WhatTarotCLI",
  platforms: [.macOS(.v15)],
  dependencies: [
    .package(
      url: "https://github.com/apple/swift-argument-parser.git",
      .upToNextMajor(from: Version(1, 2, 0))
    ),
    .package(
      url: "https://github.com/apple/swift-algorithms",
      .upToNextMajor(from: Version(1, 0, 0))
    ),
    .package(
      url: "https://github.com/pointfreeco/swift-clocks",
      .upToNextMajor(from: Version(1, 0, 0))
    )
  ],
  targets: [
    .executableTarget(
      name: "WhatTarotCLI",
      dependencies: [
        .product(name: "Algorithms", package: "swift-algorithms"),
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "Clocks", package: "swift-clocks"),
      ],
      resources: [.process("Resources/tarot.json")]
    ),
    .testTarget(
      name: "Tests",
      dependencies: [
        "WhatTarotCLI"
      ],
      path: "Tests"
    )
  ]
)
