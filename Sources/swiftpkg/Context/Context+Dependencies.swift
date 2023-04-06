import TOMLKit

extension Context {
	static func parseDependencies(_ table: TOMLTable) throws -> [Dependency] {
		try table.keys.map {
			try .init(name: $0, table: table.requireTable($0))
		}.sorted { $0.url.absoluteString.lowercased() < $1.url.absoluteString.lowercased() }
	}
}
