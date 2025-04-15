// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "errors-suite",
  platforms: [
    .iOS(.v17),
    .tvOS(.v17),
    .macOS(.v14),
    .watchOS(.v10),
    .visionOS(.v1),
  ],
  products: [
    .library(name: "ErrorsSuite", targets: ["ErrorsSuite"]),
    
    .library(name: "NetworkErrorsPack", targets: ["NetworkErrorsPack"]),
    .library(name: "HttpStatus", targets: ["HttpStatus"]),
    .library(name: "CommonErrorsPack", targets: ["CommonErrorsPack"]),
    .library(name: "BaseError", targets: ["BaseError"]),
  ],
  dependencies: [
    .package(url: "https://github.com/iDmitriyy/SwiftyKit.git", branch: "main"),
  ],
  targets: [
    .target(name: "ErrorsSuite", dependencies: [.target(name: "NetworkErrorsPack"),
                                                .target(name: "HttpStatus"),
                                                .target(name: "CommonErrorsPack"),
                                                .target(name: "BaseError"),
                                                .product(name: "SwiftyKit", package: "SwiftyKit")]),
    // TODO: import only needed parts of SwiftyKit later
    .target(name: "NetworkErrorsPack", dependencies: [.target(name: "HttpStatus"),
                                                      .target(name: "BaseError"),
                                                      .product(name: "SwiftyKit", package: "SwiftyKit")]),
    .target(name: "HttpStatus", dependencies: [.product(name: "SwiftyKit", package: "SwiftyKit")]),
    .target(name: "CommonErrorsPack", dependencies: [.target(name: "BaseError"),
                                                     .product(name: "SwiftyKit", package: "SwiftyKit")]),
    .target(name: "BaseError", dependencies: [.product(name: "SwiftyKit", package: "SwiftyKit")]),
    
    // MARK: - Test Targets
    
    .testTarget(name: "ErrorsSuiteTests", dependencies: ["ErrorsSuite"]),
  ]
)

for target: PackageDescription.Target in package.targets {
  {
    var settings: [PackageDescription.SwiftSetting] = $0 ?? []
    settings.append(.enableUpcomingFeature("ExistentialAny"))
    settings.append(.enableUpcomingFeature("InternalImportsByDefault"))
    settings.append(.enableUpcomingFeature("MemberImportVisibility"))
    $0 = settings
  }(&target.swiftSettings)
}
