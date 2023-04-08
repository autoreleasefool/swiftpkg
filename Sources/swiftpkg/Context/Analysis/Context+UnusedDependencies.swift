import Foundation

extension Context {
	private static let importRegex = #/^(@testable )?import (.*)$/#
	private static let productRegex = #/\.product\(name: "(.*?)"/#
	private static let ignoredDependencies: Set<String> = [
		"Combine",
		"Foundation",
		"MapKit",
		"SwiftUI",
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

	private static func findUsedDependencies(
		inPackage packageURL: URL,
		forTarget targetName: String
	) throws -> Set<String> {
		var dependencies: Set<String> = []
		for file in sourceFiles(inPackage: packageURL, forTarget: targetName) {
			let source = try String(contentsOf: file)
			for match in source.matches(of: importRegex.anchorsMatchLineEndings()) {
				dependencies.insert(String(match.output.2))
			}
		}

		return dependencies
	}

	private static func sourceFiles(
		inPackage packageURL: URL,
		forTarget targetName: String
	) -> [URL] {
		let targetURL = packageURL
			.appending(path: "Sources")
			.appending(path: targetName)

		let resourceKeys = Set<URLResourceKey>([.nameKey, .isDirectoryKey])
		let directoryEnumerator = FileManager.default.enumerator(
			at: targetURL,
			includingPropertiesForKeys: Array(resourceKeys),
			options: .skipsHiddenFiles
		)!

		var fileURLs: [URL] = []
		for case let fileURL as URL in directoryEnumerator {
			guard let resourceValues = try? fileURL.resourceValues(forKeys: resourceKeys),
						let isDirectory = resourceValues.isDirectory,
						let name = resourceValues.name
			else {
				continue
			}

			if !isDirectory && fileURL.absoluteString.hasSuffix(".swift") {
				fileURLs.append(fileURL)
			}
		}
		return fileURLs
	}
}
