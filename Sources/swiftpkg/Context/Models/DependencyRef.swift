import Foundation
import TOMLKit

struct DependencyRef {
	let url: URL?
	let version: Version?
	let path: String?
	let packageName: String?

	init(table: TOMLTable) throws {
		packageName = if table.contains(key: "package_name") {
			try table.requireString("package_name")
		} else {
			nil
		}

		if table.contains(key: "from") {
			version = .from(try table.requireString("from"))
			path = nil
		} else if table.contains(key: "revision") {
			version = .revision(try table.requireString("revision"))
			path = nil
		} else if table.contains(key: "branch") {
			version = .branch(try table.requireString("branch"))
			path = nil
		} else if table.contains(key: "path") {
			path = try table.requireString("path")
			version = nil
		} else {
			version = nil
			path = nil
		}

		url = if table.contains(key: "url") {
			try table.requireURL("url")
		} else {
			nil
		}
	}
}
