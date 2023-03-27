import Foundation

extension TOMLPackage {
	struct Defaults: Decodable {
		let implementation: Targets?
		let interface: Targets?
	}
}

extension TOMLPackage.Defaults {
	struct Targets: Decodable {
		let features: [String]?
		let repositories: [String]?
		let services: [String]?
		let libraries: [String]?
		let dependencies: [String]?
	}
}
