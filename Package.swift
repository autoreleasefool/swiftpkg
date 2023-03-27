// swift-tools-version: 5.7

import PackageDescription

let package = Package(
	name: "swiftpkg",
	platforms: [
		.macOS(.v13),
	],
	dependencies: [
		.package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.2"),
	],
	targets: [
		.executableTarget(
			name: "swiftpkg",
			dependencies: [
				.product(name: "ArgumentParser", package: "swift-argument-parser"),
			]
		),
		.testTarget(
			name: "swiftpkgTests",
			dependencies: [
				"swiftpkg",
			],
			path: "Tests/SwiftPKGTests"
		),
	]
)
