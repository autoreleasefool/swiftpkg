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
				try .init(name: $0, table: dependenciesTable.requireTable($0))
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

		var targetDefinitions: [TargetDefinition.Kind: [String: TargetDefinition]] = [:]
		var targets: [Target] = []

		for kind in TargetDefinition.Kind.allCases {
			targetDefinitions[kind] = [:]
			guard table.contains(key: kind.key) else { continue }
			let kindTable = try table.requireTable(kind.key)
			for targetKey in kindTable.keys {
				guard targetDefinitions[kind]?[targetKey] == nil else {
					throw DuplicateTargetError(targetName: targetKey)
				}

				let targetTable = try kindTable.requireTable(targetKey)
				let skipTests = targetTable["skip_tests"]?.bool ?? false

				let definition = TargetDefinition(name: targetKey, kind: kind, qualifier: nil)
				var target = Target(target: definition)

				if let interface = definition.interface {
					targetDefinitions[kind]?[interface.name] = interface
					try target.add(dependencyOn: interface)

					let interfaceTarget = Target(target: interface)
					targets.append(interfaceTarget)
				}

				if !skipTests {
					let tests = definition.tests
					targetDefinitions[kind]?[tests.name] = tests

					var testTarget = Target(target: tests)
					try testTarget.add(dependencyOn: definition)
				}

				targetDefinitions[kind]?[targetKey] = definition
				targets.append(target)
			}
		}

		print(targetDefinitions)
		print(targets)

		self.targets = targets
	}

	func toDictionary() -> [String: Any] {
		[
			"package": package,
			"platforms": platforms,
			"dependencies": dependencies,
		]
	}
}
