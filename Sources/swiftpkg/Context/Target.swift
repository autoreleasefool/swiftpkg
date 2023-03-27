import Foundation

enum DependencyError: Error, LocalizedError {
	case unsupportedTargetDependency(TargetDefinition.Kind, dependency: TargetDefinition.Kind)
	case targetingTestDependency
	case duplicateDependency(String)

	var errorDescription: String {
		switch self {
		case let .unsupportedTargetDependency(kind, dependency):
			return "\(kind) targets do not support \(dependency) depdencies"
		case .targetingTestDependency:
			return "Cannot depend on test targets"
		case let .duplicateDependency(name):
			return "Duplicate dependency found: \(name)"
		}
	}
}

struct Target {
	let target: TargetDefinition
	private(set) var targetDependencies: Set<Dependency>
	private(set) var dependencies: Set<Dependency>

	mutating func add(dependencyOn dependency: TargetDefinition) throws {
		guard target.kind.supportedDependencies.contains(dependency.kind) else {
			throw DependencyError.unsupportedTargetDependency(target.kind, dependency: dependency.kind)
		}

		switch dependency.modifier {
		case .interface:
			break
		case .test:
			throw DependencyError.targetingTestDependency
		case .none:
			guard !dependency.kind.dependencyRequiresInterface else {
				throw DependencyError.unsupportedTargetDependency(target.kind, dependency: dependency.kind)
			}
		}

		guard targetDependencies.insert(.init(name: target.name)).inserted else {
			throw DependencyError.duplicateDependency(dependency.name)
		}
	}

	mutating func add(dependencyOn dependency: Dependency) throws {
		guard dependencies.insert(dependency).inserted else {
			throw DependencyError.duplicateDependency(dependency.name)
		}
	}
}

extension Target {
	struct Dependency: Hashable {
		let name: String
	}
}
