import TOMLKit

struct PackageDefinition {
	let name: String
	let toolsVersion: String
	let defaultLocalization: String

	init(_ table: TOMLTable) throws {
		self.name = try table.requireString("name")
		self.toolsVersion = try table.requireString("tools_version")
		self.defaultLocalization = try table.requireString("default_localization")
	}
}
