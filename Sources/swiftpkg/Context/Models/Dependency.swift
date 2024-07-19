import Foundation
import TOMLKit

struct Dependency: Hashable {
	private static let packageRegex: Regex = {
		guard let regex = try? Regex("https://github\\.com/.*?/(.*)\\.git", as: (Substring, Substring).self) else {
			fatalError("Failed to generate regex")
		}
		return regex
	}()

	let name: String
	let url: URL
	let version: Version

	var asDependable: String {
		".product(name: \"\(name)\", package: \"\(package)\")"
	}

	var package: String {
		String((try? Self.packageRegex.wholeMatch(in: url.absoluteString)?.output.1) ?? "")
	}

	init(name: String, table: TOMLTable, depRefs: [String: DependencyRef]) throws {
		self.name = name
		var depRef: DependencyRef?
		if let depRefKey = table["dep_ref"]?.string {
			depRef = depRefs[depRefKey]
		}

		self.url = try depRef?.url ?? table.requireURL("url")
		self.version = try depRef?.version ?? Version(table: table)
	}
}

enum Version: CustomStringConvertible, Hashable {
	case from(String)
	case revision(String)
	case branch(String)

	init(table: TOMLTable) throws {
		if table.contains(key: "from") {
			self = .from(try table.requireString("from"))
		} else if table.contains(key: "revision") {
			self = .revision(try table.requireString("revision"))
		} else if table.contains(key: "branch") {
			self = .branch(try table.requireString("branch"))
		} else {
			throw MissingKeyError(key: "version (from/revision/branch)")
		}
	}

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
