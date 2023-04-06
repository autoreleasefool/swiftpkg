import TOMLKit

struct Context {
	let package: PackageDefinition
	let platforms: [Platform]
	let dependencies: [Dependency]
	let targets: [(TargetDefinition.Kind, [Target])]
	let products: [(TargetDefinition.Kind, [TargetDefinition])]

	fileprivate static let reservedKeywords = Set([
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

		var (definitions, targets) = try Self.parseDefinitions(dependencies, table)
		targets = targets.sorted { $0.definition.fullyQualifiedName < $1.definition.fullyQualifiedName }

		if table.contains(key: "defaults") {
			try Self.parseDefaults(targets, definitions, dependencies, table.requireTable("defaults"))
		}

		self.products = TargetDefinition.Kind.allCases.map { kind in
			(kind, targets.filter { $0.definition.kind == kind && $0.definition.isProduct }.map(\.definition))
		}
		self.targets = TargetDefinition.Kind.allCases.map { kind in
			(kind, targets.filter { $0.definition.kind == kind })
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
					dependencies: $0.dependencies.sorted() + $0.targetDependencies.sorted(),
					targetType: $0.definition.qualifier.targetType
				)
			}) },
			"products": products.map { ($0.categoryName, $1.map(\.fullyQualifiedName)) },
		]
	}
}

// MARK: - Targets

extension Context {
	private static func parseDefinitions(
		_ dependencies: [Dependency],
		_ table: TOMLTable
	) throws -> ([TargetDefinition.Kind: [String: TargetDefinition]], [Target]) {
		var definitions: [TargetDefinition.Kind: [String: TargetDefinition]] = [:]
		var targets: [Target] = []

		for kind in TargetDefinition.Kind.allCases {
			definitions[kind] = [:]
			guard table.contains(key: kind.key) else { continue }
			let kindTable = try table.requireTable(kind.key)
			for targetKey in kindTable.keys {
				guard definitions[kind]?[targetKey] == nil else {
					throw DuplicateTargetError(targetName: targetKey)
				}

				let targetTable = try kindTable.requireTable(targetKey)
				let skipTests = targetTable["skip_tests"]?.bool ?? false
				let suitableForDependentsMatching = targetTable["suitable_for_dependents_matching"]?.string ?? nil

				let definition = TargetDefinition(
					name: targetKey,
					kind: kind,
					qualifier: nil,
					suitableForDependentsMatching: suitableForDependentsMatching
				)
				let target = Target(definition: definition)

				if let interface = definition.interface {
//					definitions[kind]?[interface.name] = interface
					try target.add(dependencyOn: interface)

					let interfaceTarget = Target(definition: interface)
					targets.append(interfaceTarget)
				}

				if !skipTests {
					let tests = definition.tests
//					definitions[kind]?[tests.name] = tests

					let testTarget = Target(definition: tests)
					try testTarget.add(dependencyOn: definition)
					targets.append(testTarget)
				}

				definitions[kind]?[targetKey] = definition
				targets.append(target)
			}
		}

		print(definitions)
		try Self.expandDependencies(targets, definitions, dependencies, table)

		return (definitions, targets)
	}

	private static func expandDependencies(
		_ targets: [Target],
		_ definitions: [TargetDefinition.Kind: [String: TargetDefinition]],
		_ packageDependencies: [Dependency],
		_ table: TOMLTable
	) throws {
		for target in targets {
			let rootKey = "\(target.definition.kind).\(target.definition.name)"

			let kindTable = try table.requireTable(target.definition.kind.key)
			let targetTable: TOMLTable?
			switch target.definition.qualifier {
			case .none:
				targetTable = try? kindTable.requireTable(target.definition.name)
			case .interface:
				targetTable = try? kindTable.requireTable("\(target.definition.name).interface")
			case .test:
				targetTable = try? kindTable.requireTable("\(target.definition.name).tests")
			}

			guard let targetTable else { continue }

			print(rootKey)
			if targetTable.contains(key: "dependencies") {
				let dependencies = try targetTable.requireStringArray("dependencies").map { name in
					guard let dependency = packageDependencies.first(where: { $0.name == name }) else {
						throw UndefinedDependencyError(targetName: rootKey, dependencyName: name)
					}
					return dependency
				}

				for dependency in dependencies {
					try target.add(dependencyOn: dependency)
				}
			}

			for key in targetTable.keys where !reservedKeywords.contains(key) {
				guard let kind = TargetDefinition.Kind(key: key) else {
					throw InvalidValueTypeError(
						key: "\(rootKey).\(key)",
						expectedType: TargetDefinition.Kind.allCases.map(\.key).joined(separator: ",")
					)
				}

				print(targetTable)
				print(key)

				let dependencies = try targetTable.requireStringArray(key).map {
					guard let dependency = definitions[kind]?[$0] else {
						throw UndefinedDependencyError(
							targetName: "\(rootKey).\(key)",
							dependencyName: $0
						)
					}
					return dependency.interface ?? dependency
				}

				for dependency in dependencies {
					try target.add(dependencyOn: dependency)
				}
			}
		}
	}
}

// MARK: - Defaults

extension Context {
	private static func parseDefaults(
		_ targets: [Target],
		_ definitions: [TargetDefinition.Kind: [String: TargetDefinition]],
		_ dependencies: [Dependency],
		_ table: TOMLTable
	) throws {
		for key in table.keys {
			guard let kind = TargetDefinition.Kind(key: key) else {
				throw InvalidValueTypeError(
					key: "defaults.\(key)",
					expectedType: TargetDefinition.Kind.allCases.map(\.key).joined(separator: ",")
				)
			}

			let kindTable = try table.requireTable(kind.key)

			try parseDefaults(forKind: kind, withQualifier: nil, targets, definitions, dependencies, kindTable)

			if kindTable.contains(key: "tests") {
				let testsTable = try kindTable.requireTable("tests")
				try parseDefaults(forKind: kind, withQualifier: .test, targets, definitions, dependencies, testsTable)
			}

			if kindTable.contains(key: "interface") {
				let interfaceTable = try kindTable.requireTable("interface")
				try parseDefaults(forKind: kind, withQualifier: .interface, targets, definitions, dependencies, interfaceTable)
			}
		}
	}

	private static func parseDefaults(
		forKind: TargetDefinition.Kind,
		withQualifier: TargetDefinition.Qualifier?,
		_ targets: [Target],
		_ definitions: [TargetDefinition.Kind: [String: TargetDefinition]],
		_ packageDependencies: [Dependency],
		_ table: TOMLTable
	) throws {
		if table.contains(key: "dependencies") {
			let dependencyNames = try table.requireStringArray("dependencies")
			let dependencies = try dependencyNames.map { name in
				guard let dependency = packageDependencies.first(where: { $0.name == name }) else {
					throw UndefinedDependencyError(targetName: "defaults.\(forKind)", dependencyName: name)
				}
				return dependency
			}

			for target in targets where target.definition.kind == forKind && target.definition.qualifier == withQualifier {
				for dependency in dependencies {
					try target.add(dependencyOn: dependency)
				}
			}
		}

		for key in table.keys where !reservedKeywords.contains(key) {
			guard let kind = TargetDefinition.Kind(key: key) else {
				throw InvalidValueTypeError(
					key: "defaults.\(forKind.key).\(key)",
					expectedType: TargetDefinition.Kind.allCases.map(\.key).joined(separator: ",")
				)
			}

			let dependencyNames = try table.requireStringArray(key)
			let dependencies = try dependencyNames.map {
				guard let dependency = definitions[kind]?[$0] else {
					throw UndefinedDependencyError(targetName: "defaults.\(forKind)", dependencyName: $0)
				}
				return dependency
			}

			for target in targets where target.definition.kind == forKind && target.definition.qualifier == withQualifier {
				for dependency in dependencies {
					try target.add(dependencyOn: dependency)
				}
			}
		}
	}
}

// MARK: - Dependencies

extension Context {
	private static func parseDependencies(_ table: TOMLTable) throws -> [Dependency] {
		try table.keys.map {
			try .init(name: $0, table: table.requireTable($0))
		}.sorted { $0.url.absoluteString.lowercased() < $1.url.absoluteString.lowercased() }
	}
}

// MARK: - Platforms

extension Context {
	private static func parsePlatforms(_ table: TOMLTable) throws -> [Platform] {
		try table.keys.map {
			.init(name: $0, supportedVersions: try table.requireTable($0).requireStringArray("supported"))
		}.sorted { $0.name.lowercased() < $1.name.lowercased() }
	}
}
