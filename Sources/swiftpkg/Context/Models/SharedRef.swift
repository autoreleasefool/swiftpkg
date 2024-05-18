import Foundation
import TOMLKit

struct SharedRef {
	let url: URL?
	let version: Version?

	init(table: TOMLTable) throws {
		if table.contains(key: "from") {
			version = .from(try table.requireString("from"))
		} else if table.contains(key: "revision") {
			version = .revision(try table.requireString("revision"))
		} else if table.contains(key: "branch") {
			version = .branch(try table.requireString("branch"))
		} else {
			version = nil
		}

		if table.contains(key: "url") {
			url = try table.requireURL("url")
		} else {
			url = nil
		}
	}
}
