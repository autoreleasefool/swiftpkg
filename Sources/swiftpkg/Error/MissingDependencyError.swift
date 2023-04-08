import Foundation

struct MissingDependencyError: Error, LocalizedError {
	let targetName: String
	let missingDependency: String

	var errorDescription: String? {
		"Target \(targetName) has missing dependency \(missingDependency)"
	}
}
