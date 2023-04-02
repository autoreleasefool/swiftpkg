import TOMLKit

struct Context {
	let package: PackageDefinition
	let platforms: [Platform]
	let dependencies: [Dependency]
	let targets: [Target]

	init(_ table: TOMLTable) throws {
		self.package = try PackageDefinition(table)

		if table.contains(key: "dependencies") {
			let dependenciesTable = try table.requireTable("dependencies")
			self.dependencies = try dependenciesTable.keys.map {
				try .init(dependenciesTable.requireTable($0))
			}.sorted { $0.url.absoluteString.lowercased() < $1.url.absoluteString.lowercased() }
		} else {
			self.dependencies = []
		}

		if table.contains(key: "platforms") {
			let platformsTable = try table.requireTable("platforms")
			self.platforms = try platformsTable.keys.map {
				.init(name: $0, supportedVersions: try platformsTable.requireTable($0).requireStringArray("supported"))
			}.sorted { $0.name.lowercased() < $1.name.lowercased() }
		} else {
			self.platforms = []
		}

		var targetDefinitions: [TargetDefinition] = []
		for kind in TargetDefinition.Kind.allCases {
			guard table.contains(key: kind.key) else { continue }
			let kindTable = try table.requireTable(kind.key)
			for targetKey in kindTable.keys {
				let targetTable = try kindTable.requireTable(targetKey)
				let skipTests = targetTable["skip_tests"]?.bool ?? false
				let targetDefinition = TargetDefinition(name: targetKey, kind: kind, qualifier: nil, skipTests: skipTests)

				targetDefinitions.append(targetDefinition)
				if let interface = targetDefinition.interface {
					targetDefinitions.append(interface)
				}

				if let tests = targetDefinition.tests {
					targetDefinitions.append(tests)
				}
			}
		}
		print(targetDefinitions)

		self.targets = []
	}

	func toDictionary() -> [String: Any] {
		[
			"package": package,
			"platforms": platforms,
			"dependencies": dependencies,
		]
	}
}
