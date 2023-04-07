import TOMLKit

struct Context {
	let package: PackageDefinition
	let platforms: [Platform]
	let dependencies: [Dependency]
	let targets: [(TargetDefinition.Kind, [Target])]
	let products: [(TargetDefinition.Kind, [TargetDefinition])]

	static let reservedKeywords = Set([
		"interface",
		"tests",
		"dependencies",
		"skip_tests",
		"suitable_for_dependents_matching",
	])

	init(_ table: TOMLTable) throws {
		self.package = try PackageDefinition(table)

		let dependencies: [Dependency]
		if table.contains(key: "dependencies") {
			dependencies = try Self.parseDependencies(table.requireTable("dependencies"))
		} else {
			dependencies = []
		}
		self.dependencies = dependencies

		if table.contains(key: "platforms") {
			self.platforms = try Self.parsePlatforms(table.requireTable("platforms"))
		} else {
			self.platforms = []
		}

		let (definitions, targets) = try Self.parseDefinitions(dependencies, table)

		if table.contains(key: "defaults") {
			try Self.parseDefaults(targets, definitions, dependencies, table.requireTable("defaults"))
		}

		try Self.resolveTransientDependencies(in: targets)

		let sortedTargets = targets.values.sorted { $0.definition.fullyQualifiedName < $1.definition.fullyQualifiedName }
		self.products = TargetDefinition.Kind.allCases.map { kind in
			(kind, sortedTargets.filter { $0.definition.kind == kind && $0.definition.isProduct }.map(\.definition))
		}
		self.targets = TargetDefinition.Kind.allCases.map { kind in
			(kind, sortedTargets.filter { $0.definition.kind == kind })
		}
	}

	func toDictionary() -> [String: Any] {
		[
			"package": package,
			"platforms": platforms,
			"dependencies": dependencies,
			"targets": targets.map { ($0.categoryName, $1.map {
				(
					name: $0.definition.fullyQualifiedName,
					dependencies: $0.dependencies.union($0.defaultDependencies).sorted().map {
						$0.starts(with: ".") ? $0 : "\"\($0)\""
					},
					targetType: $0.definition.qualifier.targetType
				)
			}) },
			"products": products.map { ($0.categoryName, $1.map(\.fullyQualifiedName)) },
		]
	}
}
