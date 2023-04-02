import Foundation

struct MissingKeyError: Error, LocalizedError {
	let key: String

	var errorDescription: String? {
		"missing required key: \(key)"
	}
}
