import TOMLKit

extension Context {
	static func parseSharedRefs(_ table: TOMLTable) throws -> [String: SharedRef] {
		Dictionary(
			uniqueKeysWithValues: try table.keys.map {
				($0, try SharedRef(table: table.requireTable($0)))
			}
		)
	}

	static func parseDependencies(_ table: TOMLTable, sharedRefs: [String: SharedRef]) throws -> [Dependency] {
		try table.keys.map {
			try .init(name: $0, table: table.requireTable($0), sharedRefs: sharedRefs)
		}.sorted { $0.url.absoluteString.lowercased() < $1.url.absoluteString.lowercased() }
	}
}
