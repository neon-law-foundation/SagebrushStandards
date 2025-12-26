// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Standards",
    platforms: [
        .macOS(.v15)
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/fluent.git", from: "4.12.0"),
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.10.1"),
        .package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.115.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.6.3"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0"),
        .package(url: "https://github.com/swift-server/swift-aws-lambda-runtime.git", from: "1.0.0-alpha"),
    ],
    targets: [
        .target(
            name: "StandardsRules",
            dependencies: []
        ),
        .target(
            name: "StandardsDAL",
            dependencies: [
                "StandardsRules",
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Yams", package: "Yams"),
            ],
            exclude: [
                "README.md"
            ],
            resources: [
                .copy("Examples"),
                .copy("Seeds"),
            ]
        ),
        .executableTarget(
            name: "StandardsCLI",
            dependencies: [
                "StandardsRules",
                "StandardsDAL",
                .product(name: "Logging", package: "swift-log"),
            ]
        ),
        .executableTarget(
            name: "MigrationRunner",
            dependencies: [
                "StandardsDAL",
                .product(name: "AWSLambdaRuntime", package: "swift-aws-lambda-runtime"),
                .product(name: "Logging", package: "swift-log"),
            ]
        ),
        .testTarget(
            name: "StandardsDALTests",
            dependencies: [
                "StandardsDAL",
                "StandardsRules",
            ]
        ),
    ]
)
