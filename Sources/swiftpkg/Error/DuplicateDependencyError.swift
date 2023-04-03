import Foundation

struct DuplicateDependencyError: Error, LocalizedError {
	let targetName: String
	let dependencyName: String

	var errorDescription: String? {
		"Target \(targetName) has duplicate dependency on \(dependencyName)"
	}
}
