import Foundation

struct DuplicateTargetError: Error, LocalizedError {
	let targetName: String

	var errorDescription: String? {
		"Duplicate target definition for \(targetName)"
	}
}
