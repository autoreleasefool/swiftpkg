import Foundation

struct TOMLPackage: Decodable {
	let name: String
	let toolsVersion: String
	let defaultLocalization: String
	let platforms: [String: TOMLPackage.Platform]

	let dependencies: [String: TOMLPackage.Dependencies]
	let libraries: [String: TOMLPackage.Library]

	let defaults: [String: TOMLPackage.Defaults]
}

extension TOMLPackage {
	enum CodingKeys: String, CodingKey {
		case name
		case toolsVersion = "tools_version"
		case defaultLocalization = "default_localization"
		case platforms
		case dependencies
		case libraries
		case defaults
	}
}
