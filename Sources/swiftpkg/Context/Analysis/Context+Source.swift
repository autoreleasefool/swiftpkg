import Foundation

extension Context {
	private static let importRegex = #/^(@testable|@_exported )?import (.*)$/#

	static func findUsedDependencies(
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

	static func sourceFiles(
		inPackage packageURL: URL,
		forTarget targetName: String
	) -> [URL] {
		let targetURL = packageURL
			.appending(path: "Sources")
			.appending(path: targetName)

		let resourceKeys = Set<URLResourceKey>([.isDirectoryKey])
		let directoryEnumerator = FileManager.default.enumerator(
			at: targetURL,
			includingPropertiesForKeys: Array(resourceKeys),
			options: .skipsHiddenFiles
		)!

		var fileURLs: [URL] = []
		for case let fileURL as URL in directoryEnumerator {
			guard let resourceValues = try? fileURL.resourceValues(forKeys: resourceKeys),
						let isDirectory = resourceValues.isDirectory
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
