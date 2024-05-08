import Foundation
import TOMLKit

struct Context {
	let package: PackageDefinition
	let platforms: [Platform]
	let dependencies: [Dependency]
	let targets: [String: Target]

	static let reservedKeywords = Set([
		"interface",
		"tests",
		"dependencies",
		"skip_tests",
		"suitable_for_dependents_matching",
		"resources",
	])

	init(_ table: TOMLTable) throws {
		self.package = try PackageDefinition(table)

		let versionRefs: [String: Version]
		if table.contains(key: "versionRefs") {
			versionRefs = try Self.parseVersionRefs(table.requireTable("versionRefs"))
		} else {
			versionRefs = [:]
		}

		let dependencies: [Dependency]
		if table.contains(key: "dependencies") {
			dependencies = try Self.parseDependencies(table.requireTable("dependencies"), versionRefs: versionRefs)
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
		self.targets = targets
	}

	func toDictionary() -> [String: Any] {
		let sortedTargets = targets.values.sorted {
			$0.definition.fullyQualifiedName < $1.definition.fullyQualifiedName
		}

		let targets = TargetDefinition.Kind.allCases.map { kind in
			(kind, sortedTargets.filter { $0.definition.kind == kind })
		}.map { ($0.categoryName, $1.map {
			(
				name: $0.definition.fullyQualifiedName,
				dependencies: $0.dependencies.union($0.defaultDependencies).sorted().map {
					$0.starts(with: ".") ? $0 : "\"\($0)\""
				},
				resources: $0.resources,
				targetType: $0.definition.qualifier.targetType
			)
		})
		}

		let products = TargetDefinition.Kind.allCases.map { kind in
			(
				kind,
				sortedTargets.filter { $0.definition.kind == kind && $0.definition.isProduct }.map(\.definition)
			)
		}.map { ($0.categoryName, $1.map(\.fullyQualifiedName)) }

		var dependencyUrls: Set<URL> = []
		let dedupedDependencies = dependencies.filter {
			dependencyUrls.insert($0.url).inserted
		}

		return [
			"package": package,
			"platforms": platforms,
			"dependencies": dedupedDependencies,
			"targets": targets,
			"products": products,
		]
	}
}
