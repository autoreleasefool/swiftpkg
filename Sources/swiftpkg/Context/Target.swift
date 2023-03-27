import Foundation

enum DependencyError: Error, LocalizedError {
	case unsupportedTargetDependency(Target.Kind, dependency: Target.Kind)
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
	let name: String
	let kind: Kind
	let modifier: Modifier?
	let isProduct: Bool
	private(set) var targetDependencies: Set<String>
	private(set) var dependencies: Set<Dependency>

	mutating func add(dependencyOn target: Target) throws {
		guard kind.supportedDependencies.contains(target.kind) else {
			throw DependencyError.unsupportedTargetDependency(kind, dependency: target.kind)
		}

		switch target.modifier {
		case .interface:
			break
		case .test:
			throw DependencyError.targetingTestDependency
		case .none:
			guard !target.kind.dependencyRequiresInterface else {
				throw DependencyError.unsupportedTargetDependency(kind, dependency: target.kind)
			}
		}

		guard targetDependencies.insert(target.name).inserted else {
			throw DependencyError.duplicateDependency(target.name)
		}
	}

	mutating func add(dependencyOn dependency: Dependency) throws {
		guard dependencies.insert(dependency).inserted else {
			throw DependencyError.duplicateDependency(dependency.name)
		}
	}
}

extension Target {
	enum Kind: String, CaseIterable {
		case feature = "Features"
		case repository = "Repositories"
		case service = "Services"
		case library = "Libraries"

		var dependencyRequiresInterface: Bool {
			switch self {
			case .feature, .library:
				return false
			case .service, .repository:
				return true
			}
		}

		var supportedDependencies: [Kind] {
			switch self {
			case .feature:
				return [.feature, .repository, .service, .library]
			case .repository:
				return [.repository, .service, .library]
			case .service:
				return [.service, .library]
			case .library:
				return [.library]
			}
		}
	}
}

extension Target {
	enum Modifier {
		case test
		case interface
	}
}
