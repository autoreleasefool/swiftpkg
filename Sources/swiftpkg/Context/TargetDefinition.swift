import Foundation
import TOMLKit

struct TargetDefinition {
	let name: String
	let kind: Kind
	let qualifier: Qualifier?
	let skipTests: Bool

	var interface: TargetDefinition? {
		return kind.requiresInterface
			? .init(name: "\(name)Interface", kind: kind, qualifier: .interface, skipTests: true)
			: nil
	}

	var tests: TargetDefinition? {
		return skipTests
			? nil
		: .init(name: "\(name)Tests", kind: kind, qualifier: .test, skipTests: true)
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
