import Foundation
import TOMLKit

struct Context {
	let package: PackageDefinition
	let platforms: [Platform]
	let dependencies: [Dependency]
	let targets: [String: Target]

	let productRegex = #/\.product\(name: "(.*?)"/#

	static let reservedKeywords = Set([
		"copied",
		"dependencies",
		"interface",
		"processed",
		"resources",
		"skip_tests",
		"skip_interface",
		"suitable_for_dependents_matching",
		"swift_settings",
		"tests",
	])

	init(_ table: TOMLTable) throws {
		self.package = try PackageDefinition(table)

		let sharedDepRefs: [String: DependencyRef]
		let sharedSwiftSettings: [String]
		if table.contains(key: "shared") {
			let sharedTable = try table.requireTable("shared")
			sharedDepRefs = if sharedTable.contains(key: "refs") {
				try Self.parseDependencyRefs(sharedTable.requireTable("refs"))
			} else {
				[:]
			}
			sharedSwiftSettings = if sharedTable.contains(key: "swift_settings") {
				try sharedTable.requireStringArray("swift_settings")
			} else {
				[]
			}
		} else {
			sharedDepRefs = [:]
			sharedSwiftSettings = []
		}

		let dependencies: [Dependency]
		if table.contains(key: "dependencies") {
			dependencies = try Self.parseDependencies(table.requireTable("dependencies"), depRefs: sharedDepRefs)
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

		for swiftSwetting in sharedSwiftSettings {
			for target in targets.values {
				target.add(swiftSetting: swiftSwetting)
			}
		}

		try Self.resolveTransientDependencies(in: targets)
		self.targets = targets
	}

	func toDictionary() -> [String: Any] {
		let sortedTargets = targets.values.sorted {
			$0.definition.fullyQualifiedName < $1.definition.fullyQualifiedName
		}

		let targets = TargetDefinition.Kind.allCases
			.map { kind in
				(kind, sortedTargets.filter { $0.definition.kind == kind })
			}
			.map {
				(
					$0.categoryName,
					$1.map {
						(
							name: $0.definition.fullyQualifiedName,
							dependencies: $0.dependencies.union($0.defaultDependencies).sorted().map {
								$0.starts(with: ".") ? $0 : "\"\($0)\""
							},
							resources: $0.resources,
							swiftSettings: $0.swiftSettings,
							targetType: $0.definition.qualifier.targetType
						)
					}
				)
			}

		let products = TargetDefinition.Kind.allCases
			.map { kind in
				(
					kind,
					sortedTargets.filter { $0.definition.kind == kind && $0.definition.isProduct }.map(\.definition)
				)
			}
			.map { ($0.categoryName, $1.map(\.fullyQualifiedName)) }

		var dependencyNames: Set<String> = []
		let dedupedDependencies = dependencies
			.filter {
				dependencyNames.insert($0.id).inserted
			}
			.map(\.packaged)

		return [
			"package": package,
			"platforms": platforms,
			"packagedDependencies": dedupedDependencies,
			"targets": targets,
			"products": products,
		]
	}
}
