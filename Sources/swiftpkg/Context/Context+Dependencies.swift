import TOMLKit

extension Context {
	static func parseDependencyRefs(_ table: TOMLTable) throws -> [String: DependencyRef] {
		Dictionary(
			uniqueKeysWithValues: try table.keys.map {
				($0, try DependencyRef(table: table.requireTable($0)))
			}
		)
	}

	static func parseDependencies(_ table: TOMLTable, depRefs: [String: DependencyRef]) throws -> [Dependency] {
		try table.keys.map {
			try .init(name: $0, table: table.requireTable($0), depRefs: depRefs)
		}.sorted { $0.url.absoluteString.lowercased() < $1.url.absoluteString.lowercased() }
	}
}
