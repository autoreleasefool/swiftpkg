import Foundation

struct InvalidValueTypeError: Error, LocalizedError {
	let key: String
	let expectedType: String

	var errorDescription: String? {
		"\(key) must be \(expectedType)"
	}
}
