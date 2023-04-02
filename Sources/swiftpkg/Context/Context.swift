import TOMLKit

struct Context {
	let package: PackageDefinition
	let platforms: [(platform: String, supported: [String])]
	let dependencies: [Dependency]
	let targets: [Target]
	let products: [(kind: String, products: [TargetDefinition])]

	init(_ table: TOMLTable) throws {
		self.package = try PackageDefinition(table)

		if table.contains(key: "dependencies") {
			let dependenciesTable = try table.requireTable("dependencies")
			self.dependencies = try dependenciesTable.keys.map {
				try .init(dependenciesTable.requireTable($0))
			}.sorted { $0.url.absoluteString < $1.url.absoluteString }
		} else {
			self.dependencies = []
		}

		if table.contains(key: "platforms") {
			let platformsTable = try table.requireTable("platforms")
			self.platforms = try platformsTable.keys.map {
				($0, try platformsTable.requireTable($0).requireStringArray("supported"))
			}.sorted { $0.platform < $1.platform }
		} else {
			self.platforms = []
		}

		self.targets = []
		self.products = []
	}

	func toDictionary() -> [String: Any] {
		[
			"package": package,
			"platforms": platforms,
			"products": products,
			"dependencies": dependencies,
		]
	}
}
