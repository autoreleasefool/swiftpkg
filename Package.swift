// swift-tools-version: 5.7

import PackageDescription

let package = Package(
	name: "swiftpkg",
	platforms: [
		.macOS(.v13),
	],
	dependencies: [
	],
	targets: [
		.executableTarget(
			name: "swiftpkg",
			dependencies: []
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
