import Foundation

struct UnusedDependencyError: Error, LocalizedError {
	let targetName: String
	let unusedDependency: String

	var errorDescription: String? {
		"Target \(targetName) has unused dependency \(unusedDependency)"
	}
}
