import Foundation

struct MissingTargetError: Error, LocalizedError {
	let targetName: String

	var errorDescription: String? {
		"Target \(targetName) could not be found. This is an internal error and should not occur."
	}
}
