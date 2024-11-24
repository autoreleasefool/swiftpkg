import TOMLKit

extension Context {
	static func parsePlatforms(_ table: TOMLTable) throws -> [Platform] {
		try table.keys
			.map {
				.init(name: $0, supportedVersions: try table.requireTable($0).requireStringArray("supported"))
			}
			.sorted { $0.name.lowercased() < $1.name.lowercased() }
	}
}
