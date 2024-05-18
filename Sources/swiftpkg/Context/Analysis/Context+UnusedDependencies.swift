import Foundation

extension Context {
	static let productRegex = #/\.product\(name: "(.*?)"/#
	static let ignoredDependencies: Set<String> = [
		"AppKit",
		"Charts",
		"Combine",
		"CoreLocation",
		"Foundation",
		"MapKit",
		"MessageUI",
		"OSLog",
		"StoreKit",
		"SwiftUI",
		"UIKit",
		"UniformTypeIdentifiers",
		"XCTest",
	]

	func warnUnusedDependencies(inPackage packageURL: URL) throws {
		var cache: [String: CachedDependencies] = [:]
		for (targetName, target) in targets {
			guard target.definition.qualifier != .test else { continue }

			let definedDependencies = Set(
				try Self.resolveTransientDependencies(for: targetName, in: targets, cache: &cache)
				.dependencies.map {
					if $0.starts(with: ".") {
						return String($0.firstMatch(of: Self.productRegex)?.1 ?? "")
					} else {
						return $0
					}
				}
			).subtracting(target.defaultDependencies)
			let usedDependencies = try Self.findUsedDependencies(inPackage: packageURL, forTarget: targetName)
				.subtracting(Self.ignoredDependencies)

			let unusedDependencies = definedDependencies.subtracting(usedDependencies)

			if let unusedDependency = unusedDependencies.first {
				throw UnusedDependencyError(
					targetName: targetName,
					unusedDependency: unusedDependency
				)
			}
		}
	}
}
