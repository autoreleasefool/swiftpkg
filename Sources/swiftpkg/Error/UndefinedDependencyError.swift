import Foundation

struct UndefinedDependencyError: Error, LocalizedError {
	let targetName: String
	let dependencyName: String

	var errorDescription: String? {
		"Target \(targetName) depends on unknown dependency \(dependencyName)"
	}
}
