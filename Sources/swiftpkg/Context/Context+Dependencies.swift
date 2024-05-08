import TOMLKit

extension Context {
	static func parseVersionRefs(_ table: TOMLTable) throws -> [String: Version] {
		Dictionary(
			uniqueKeysWithValues: try table.keys.map {
				($0, try Version(table: table.requireTable($0), versionRefs: [:]))
			}
		)
	}

	static func parseDependencies(_ table: TOMLTable, versionRefs: [String: Version]) throws -> [Dependency] {
		try table.keys.map {
			try .init(name: $0, table: table.requireTable($0), versionRefs: versionRefs)
		}.sorted { $0.url.absoluteString.lowercased() < $1.url.absoluteString.lowercased() }
	}
}
