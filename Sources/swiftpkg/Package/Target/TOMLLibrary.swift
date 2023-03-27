import Foundation

extension TOMLPackage {
	struct Library: TOMLTarget, Decodable {
		let requiresTests: Bool?
		let suitableForDependenciesMatching: Bool?

		let libraries: [String]?
		let dependencies: [String]?
	}
}
