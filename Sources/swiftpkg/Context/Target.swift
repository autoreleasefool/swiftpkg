import Foundation

class Target {
	let definition: TargetDefinition
	private(set) var targetDependencies: Set<String> = []
	private(set) var dependencies: Set<String> = []

	init(definition: TargetDefinition) {
		self.definition = definition
	}

	func add(dependencyOn dependency: TargetDefinition) throws {
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

		guard targetDependencies.insert(dependency.fullyQualifiedName).inserted else {
			throw DuplicateDependencyError(
				targetName: definition.fullyQualifiedName,
				dependencyName: dependency.fullyQualifiedName
			)
		}
	}

	func add(dependencyOn dependency: Dependency) throws {
		guard dependencies.insert(dependency.name).inserted else {
			throw DuplicateDependencyError(
				targetName: definition.fullyQualifiedName,
				dependencyName: dependency.name
			)
		}
	}
}
