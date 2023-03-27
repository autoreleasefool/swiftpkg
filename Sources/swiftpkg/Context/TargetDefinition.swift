import Foundation

struct TargetDefinition {
	let name: String
	let kind: Kind
	let modifier: Modifier?
	let isProduct: Bool
}

extension TargetDefinition {
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

extension TargetDefinition {
	enum Modifier {
		case test
		case interface
	}
}
