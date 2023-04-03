import Foundation

struct Target {
	let target: TargetDefinition
	private(set) var targetDependencies: Set<String> = []
	private(set) var dependencies: Set<String> = []

	init(target: TargetDefinition) {
		self.target = target
	}

	mutating func add(dependencyOn dependency: TargetDefinition) throws {
		switch target.qualifier {
		case .interface, .none:
			guard target.kind.supportedDependencies.contains(dependency.kind) else {
				throw UnsupportedTargetDependencyError(
					targetName: target.name,
					targetKind: target.kind,
					dependencyName: dependency.name,
					dependencyKind: dependency.kind
				)
			}

			switch dependency.qualifier {
			case .interface:
				break
			case .test:
				throw TestTargetDependencyError(targetName: target.name, dependencyName: dependency.name)
			case .none:
				guard !dependency.kind.requiresInterface else {
					throw UnsupportedTargetDependencyError(
						targetName: target.name,
						targetKind: target.kind,
						dependencyName: dependency.name,
						dependencyKind: dependency.kind
					)
				}
			}
		case .test:
			break
		}

		guard targetDependencies.insert(dependency.name).inserted else {
			throw DuplicateDependencyError(targetName: target.name, dependencyName: dependency.name)
		}
	}

	mutating func add(dependencyOn dependency: Dependency) throws {
		guard dependencies.insert(dependency.name).inserted else {
			throw DuplicateDependencyError(targetName: target.name, dependencyName: dependency.name)
		}
	}
}
