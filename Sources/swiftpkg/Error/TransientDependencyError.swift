import Foundation

struct TransientDependencyError: Error, LocalizedError {
	let targetName: String
	let dependencyName: String

	var errorDescription: String? {
		"Target \(targetName) has transient dependency \(dependencyName)"
	}
}
