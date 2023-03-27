// swift-tools-version: 5.7

import PackageDescription

let package = Package(
	name: "swiftpkg",
	platforms: [
		.macOS(.v13),
	],
	dependencies: [
		.package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.2"),
		.package(url: "https://github.com/LebJe/TOMLKit.git", from: "0.5.4"),
		.package(url: "https://github.com/stencilproject/Stencil.git", from: "0.15.1"),
	],
	targets: [
		.executableTarget(
			name: "swiftpkg",
			dependencies: [
				.product(name: "ArgumentParser", package: "swift-argument-parser"),
				.product(name: "Stencil", package: "Stencil"),
				.product(name: "TOMLKit", package: "TOMLKit"),
			],
			resources: [
				.copy("Template"),
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
