import Foundation

struct TOMLPackage: Decodable {
	let name: String
	let toolsVersion: String
	let defaultLocalization: String

	let dependencies: [String: TOMLPackage.Dependencies]
}

extension TOMLPackage {
	enum CodingKeys: String, CodingKey {
		case name
		case toolsVersion = "tools_version"
		case defaultLocalization = "default_localization"
		case dependencies
	}
}
