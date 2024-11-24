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
		try table.keys
			.map {
				try .init(name: $0, table: table.requireTable($0), depRefs: depRefs)
			}
			.sorted {
				switch ($0, $1) {
				case let (.local(l1), .local(l2)):
					l1.name.lowercased() < l2.name.lowercased()
				case let (.remote(r1), .remote(r2)):
					r1.url.absoluteString.lowercased() < r2.url.absoluteString.lowercased()
				case (.local, .remote):
					false
				case (.remote, .local):
					true
				}
			}
	}
}
