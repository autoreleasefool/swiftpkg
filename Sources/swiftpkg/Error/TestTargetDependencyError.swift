import Foundation

struct TestTargetDependencyError: Error, LocalizedError {
	let targetName: String
	let dependencyName: String

	var errorDescription: String? {
		"Target \(targetName) cannot depend on test target \(dependencyName)"
	}
}
