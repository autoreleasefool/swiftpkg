import Foundation
import TOMLKit

struct TargetDefinition: Hashable {
	let name: String
	let kind: Kind
	let qualifier: Qualifier?

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
		return kind.requiresInterface
			? .init(name: name, kind: kind, qualifier: .interface)
			: nil
	}

	var tests: TargetDefinition {
		.init(name: name, kind: kind, qualifier: .test)
	}
}

extension TargetDefinition {
	enum Kind: CaseIterable {
		case feature
//		case repository
		case dataProvider
		case service
		case library

		var key: String {
			switch self {
			case .feature: return "features"
//			case .repository: return "repositories"
			case .dataProvider: return "dataProviders"
			case .service: return "services"
			case .library: return "libraries"
			}
		}

		var qualifiedName: String {
			switch self {
			case .feature: return "Feature"
			case .dataProvider: return "DataProvider"
			case .service: return "Service"
			case .library: return "Library"
			}
		}

		var requiresInterface: Bool {
			switch self {
			case .feature, .library:
				return false
			case .service, .dataProvider:
				return true
			}
		}

		var supportedDependencies: [Kind] {
			switch self {
			case .feature:
				return [.feature, .dataProvider, .service, .library]
			case .dataProvider:
				return [.dataProvider, .service, .library]
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
