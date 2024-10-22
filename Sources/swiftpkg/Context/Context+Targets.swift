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
				let skipInterface = targetTable["skip_interface"]?.bool ?? false
				let suitableForDependentsMatching = targetTable["suitable_for_dependents_matching"]?.string ?? nil

				let definition = TargetDefinition(
					name: targetKey,
					kind: kind,
					qualifier: nil,
					suitableForDependentsMatching: suitableForDependentsMatching
				)
				let target = Target(definition: definition)
				var subTargets: [Target] = []

				if let interface = definition.interface, !skipInterface {
					try target.add(dependencyOn: interface)

					let interfaceTarget = Target(definition: interface)
					targets[interfaceTarget.definition.fullyQualifiedName] = interfaceTarget
					subTargets.append(interfaceTarget)

					if let interfaceTable = targetTable["interface"]?.table {
						try processArguments(forTarget: interfaceTarget, withTable: interfaceTable)
					}
				}

				if !skipTests {
					let tests = definition.tests

					let testTarget = Target(definition: tests)
					try testTarget.add(dependencyOn: definition)
					targets[testTarget.definition.fullyQualifiedName] = testTarget
					subTargets.append(testTarget)

					if let testTable = targetTable["tests"]?.table {
						try processArguments(forTarget: testTarget, withTable: testTable)
					}
				}

				try processArguments(forTarget: target, withTable: targetTable)

				definitions[kind]?[targetKey] = definition
				targets[definition.fullyQualifiedName] = target
			}
		}

		try expandDependencies(targets, definitions, dependencies, table)

		return (definitions, targets)
	}

	private static func processArguments(forTarget target: Target, withTable targetTable: TOMLTable) throws {
		if targetTable.contains(key: "resources") {
			try target.addResources(from: targetTable.requireTable("resources"))
		}

		if targetTable.contains(key: "swift_settings") {
			for setting in try targetTable.requireStringArray("swift_settings") {
				target.add(swiftSetting: setting)
			}
		}
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
				targetTable = kindTable[target.definition.name]?.table
			case .interface:
				targetTable = kindTable[target.definition.name]?.table?["interface"]?.table
			case .test:
				targetTable = kindTable[target.definition.name]?.table?["tests"]?.table
			}

			guard let targetTable else { continue }

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

					return target.definition.qualifier == .test ? dependency : dependency.interface ?? dependency
				}

				for dependency in dependencies {
					try target.add(dependencyOn: dependency)
				}
			}
		}
	}
}
