import Foundation
import TOMLKit

enum Dependency: Hashable, Identifiable {
	case remote(RemoteDependency)
	case local(LocalDependency)

	init(name: String, table: TOMLTable, depRefs: [String: DependencyRef]) throws {
		let depRef: DependencyRef? = if let depRefKey = table["dep_ref"]?.string {
			depRefs[depRefKey]
		} else {
			nil
		}

		if table.contains(key: "path") || depRef?.path != nil {
			self = try .local(LocalDependency(name: name, table: table, depRef: depRef))
		} else {
			self = try .remote(RemoteDependency(name: name, table: table, depRef: depRef))
		}
	}

	var id: String {
		switch self {
		case let .local(local): local.id
		case let .remote(remote): remote.id
		}
	}

	var asDependable: String {
		switch self {
		case let .local(local): local.asDependable
		case let .remote(remote): remote.asDependable
		}
	}

	var name: String {
		switch self {
		case let .local(local): local.name
		case let .remote(remote): remote.name
		}
	}

	var packaged: String {
		switch self {
		case let .remote(remote): ".package(url: \"\(remote.url)\", \(remote.version))"
		case let .local(local): ".package(path: \"\(local.path)\")"
		}
	}
}

struct LocalDependency: Hashable, Identifiable {
	let name: String
	let path: String
	let package: String

	var id: String { path }

	var asDependable: String {
		".product(name: \"\(name)\", package: \"\(package)\")"
	}

	init(name: String, table: TOMLTable, depRef: DependencyRef?) throws {
		self.name = name
		self.path = try depRef?.path ?? table.requireString("path")
		self.package = depRef?.packageName ?? table["package_name"]?.string ?? name
	}
}

struct RemoteDependency: Hashable, Identifiable {
	let name: String
	let url: URL
	let version: Version

	var id: String { url.absoluteString }

	var asDependable: String {
		".product(name: \"\(name)\", package: \"\(package)\")"
	}

	var package: String {
		let packageRegex: Regex = {
			guard let regex = try? Regex("https://github\\.com/.*?/(.*)\\.git", as: (Substring, Substring).self) else {
				fatalError("Failed to generate regex")
			}
			return regex
		}()

		return String((try? packageRegex.wholeMatch(in: url.absoluteString)?.output.1) ?? "")
	}

	init(name: String, table: TOMLTable, depRef: DependencyRef?) throws {
		self.name = name
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
