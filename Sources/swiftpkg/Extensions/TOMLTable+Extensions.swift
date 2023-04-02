import Foundation
import TOMLKit

extension TOMLTable {
	func require(_ key: String) throws -> TOMLValueConvertible {
		guard let value = self[key] else {
			throw MissingKeyError(key: key)
		}
		return value
	}

	func requireString(_ key: String) throws -> String {
		guard let value = try require(key).string else {
			throw InvalidValueTypeError(key: key, expectedType: "String")
		}
		return value
	}

	func requireURL(_ key: String) throws -> URL {
		guard let string = try require(key).string, let url = URL(string: string) else {
			throw InvalidValueTypeError(key: key, expectedType: "URL")
		}
		return url
	}

	func requireTable(_ key: String) throws -> TOMLTable {
		guard let value = try require(key).table else {
			throw InvalidValueTypeError(key: key, expectedType: "Table")
		}
		return value
	}

	func requireStringArray(_ key: String) throws -> [String] {
		guard let value = try require(key).array else {
			throw InvalidValueTypeError(key: key, expectedType: "Array")
		}
		let array = try value.compactMap {
			guard let element = $0.string else {
				throw InvalidValueTypeError(key: key, expectedType: "[String]")
			}
			return element
		}
		return array
	}
}
