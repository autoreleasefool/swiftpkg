import TOMLKit

extension Context {
	static func parseDefinitions(
		_ dependencies: [Dependency],
		_ table: TOMLTable
	) throws -> ([TargetDefinition.Kind: [String: TargetDefinition]], [String: Target]) {
		var definitions: [TargetDefinition.Kind: [String: TargetDefinition]] = [:]
		var targets: [String: Target] = [:]

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
					try target.add(dependencyOn: interface)

					let interfaceTarget = Target(definition: interface)
					targets[interfaceTarget.definition.fullyQualifiedName] = interfaceTarget
				}

				if !skipTests {
					let tests = definition.tests

					let testTarget = Target(definition: tests)
					try testTarget.add(dependencyOn: definition)
					targets[testTarget.definition.fullyQualifiedName] = testTarget
				}

				definitions[kind]?[targetKey] = definition
				targets[definition.fullyQualifiedName] = target
			}
		}

		try Self.expandDependencies(targets, definitions, dependencies, table)

		return (definitions, targets)
	}

	static func expandDependencies(
		_ targets: [String: Target],
		_ definitions: [TargetDefinition.Kind: [String: TargetDefinition]],
		_ packageDependencies: [Dependency],
		_ table: TOMLTable
	) throws {
		for target in targets.values {
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
