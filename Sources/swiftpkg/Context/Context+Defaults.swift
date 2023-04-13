import TOMLKit

extension Context {
	static func parseDefaults(
		_ targets: [String: Target],
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

	static func parseDefaults(
		forKind: TargetDefinition.Kind,
		withQualifier: TargetDefinition.Qualifier?,
		_ targets: [String: Target],
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

			for target in targets.values
				where target.definition.kind == forKind && target.definition.qualifier == withQualifier {
				for dependency in dependencies {
					try target.add(dependencyOn: dependency, asDefault: true)
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

			for target in targets.values
				where target.definition.kind == forKind && target.definition.qualifier == withQualifier {
				for dependency in dependencies {
					let dep = target.definition.qualifier == .test ? dependency : dependency.interface ?? dependency
					try target.add(dependencyOn: dep, asDefault: true)
				}
			}
		}
	}
}
