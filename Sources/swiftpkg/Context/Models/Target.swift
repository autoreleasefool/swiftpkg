import Foundation

class Target {
	let definition: TargetDefinition
	private(set) var dependencies: Set<String> = []
	private(set) var defaultDependencies: Set<String> = []

	init(definition: TargetDefinition) {
		self.definition = definition
	}

	func add(dependencyOn dependency: TargetDefinition, asDefault: Bool = false) throws {
		switch definition.qualifier {
		case .interface, .none:
			guard definition.kind.supportedDependencies.contains(dependency.kind) else {
				throw UnsupportedTargetDependencyError(
					targetName: definition.fullyQualifiedName,
					targetKind: definition.kind,
					dependencyName: dependency.fullyQualifiedName,
					dependencyKind: dependency.kind
				)
			}

			switch dependency.qualifier {
			case .interface:
				break
			case .test:
				throw TestTargetDependencyError(
					targetName: definition.fullyQualifiedName,
					dependencyName: dependency.fullyQualifiedName
				)
			case .none:
				guard !dependency.kind.requiresInterface else {
					throw UnsupportedTargetDependencyError(
						targetName: definition.fullyQualifiedName,
						targetKind: definition.kind,
						dependencyName: dependency.fullyQualifiedName,
						dependencyKind: dependency.kind
					)
				}
			}
		case .test:
			break
		}

		if let suitableForDependentsMatching = dependency.suitableForDependentsMatching,
				let suitableRegex = try? Regex(suitableForDependentsMatching) {
			guard definition.fullyQualifiedName.wholeMatch(of: suitableRegex) != nil else {
				throw UnsupportedTargetDependencyError(
					targetName: definition.fullyQualifiedName,
					targetKind: definition.kind,
					dependencyName: dependency.fullyQualifiedName,
					dependencyKind: dependency.kind
				)
			}
		}

		let key = "\(dependency.fullyQualifiedName)"
		let inserted = asDefault
			? defaultDependencies.insert(key).inserted
			: dependencies.insert(key).inserted

		guard inserted || definition.fullyQualifiedName.contains(dependency.fullyQualifiedName) else {
			throw DuplicateDependencyError(
				targetName: definition.fullyQualifiedName,
				dependencyName: dependency.fullyQualifiedName
			)
		}
	}

	func add(dependencyOn dependency: Dependency, asDefault: Bool = false) throws {
		let key = dependency.asDependable
		let inserted = asDefault
			? defaultDependencies.insert(key).inserted
			: dependencies.insert(key).inserted

		guard inserted else {
			throw DuplicateDependencyError(
				targetName: definition.fullyQualifiedName,
				dependencyName: dependency.name
			)
		}
	}

	func removeDefault(dependencyOn: String) {
		defaultDependencies.remove(dependencyOn)
	}
}
