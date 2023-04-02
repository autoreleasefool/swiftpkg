import Foundation
import TOMLKit

struct Dependency: Hashable {
	let url: URL
	let version: Version

	init(_ table: TOMLTable) throws {
		self.url = try table.requireURL("url")
		if table.contains(key: "from") {
			self.version = .from(try table.requireString("from"))
		} else if table.contains(key: "revision") {
			self.version = .revision(try table.requireString("revision"))
		} else if table.contains(element: "branch") {
			self.version = .branch(try table.requireString("branch"))
		} else {
			throw MissingKeyError(key: "version (from/revision/branch)")
		}
	}
}

enum Version: CustomStringConvertible, Hashable {
	case from(String)
	case revision(String)
	case branch(String)

	var description: String {
		switch self {
		case let .from(from):
			return "from: \"\(from)\""
		case let .revision(revision):
			return "revision: \"\(revision)\""
		case let .branch(branch):
			return "branch: \"\(branch)\""
		}
	}
}
