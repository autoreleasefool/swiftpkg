import Foundation
import TOMLKit

struct TargetDefinition: Hashable {
	let name: String
	let kind: Kind
	let qualifier: Qualifier?
	let suitableForDependentsMatching: String?

	var fullyQualifiedName: String {
		let qualifierName: String
		switch qualifier {
		case .none:
			qualifierName = ""
		case .interface:
			qualifierName = "Interface"
		case .test:
			qualifierName = "Tests"
		}

		return "\(name)\(kind.qualifiedName)\(qualifierName)"
	}

	var interface: TargetDefinition? {
		kind.requiresInterface
			? .init(name: name, kind: kind, qualifier: .interface, suitableForDependentsMatching: suitableForDependentsMatching)
			: nil
	}

	var tests: TargetDefinition {
		.init(name: name, kind: kind, qualifier: .test, suitableForDependentsMatching: suitableForDependentsMatching)
	}

	var isProduct: Bool {
		switch qualifier {
		case .none, .interface:
			return true
		case .test:
			return false
		}
	}
}

extension TargetDefinition {
	enum Kind: CaseIterable {
		case feature
		case repository
		case dataProvider
		case service
		case library

		init?(key: String) {
			switch key {
			case "features": self = .feature
			case "dataProviders": self = .dataProvider
			case "repositories": self = .repository
			case "services": self = .service
			case "libraries": self = .library
			default: return nil
			}
		}

		var key: String {
			switch self {
			case .feature: return "features"
			case .repository: return "repositories"
			case .dataProvider: return "dataProviders"
			case .service: return "services"
			case .library: return "libraries"
			}
		}

		var qualifiedName: String {
			switch self {
			case .feature: return "Feature"
			case .dataProvider: return "DataProvider"
			case .repository: return "Repository"
			case .service: return "Service"
			case .library: return "Library"
			}
		}

		var categoryName: String {
			switch self {
			case .feature: return "Features"
			case .dataProvider: return "Data Providers"
			case .repository: return "Repositories"
			case .service: return "Services"
			case .library: return "Libraries"
			}
		}

		var requiresInterface: Bool {
			switch self {
			case .feature, .library:
				return false
			case .service, .dataProvider, .repository:
				return true
			}
		}

		var supportedDependencies: [Kind] {
			switch self {
			case .feature:
				return [.feature, .dataProvider, .repository, .service, .library]
			case .dataProvider:
				return [.dataProvider, .service, .library]
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

extension TargetDefinition {
	enum Qualifier {
		case test
		case interface
	}
}

extension Optional where Wrapped == TargetDefinition.Qualifier {
	var targetType: String {
		switch self {
		case .interface, .none:
			return "target"
		case .test:
			return "testTarget"
		}
	}
}
