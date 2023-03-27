import Foundation

extension TOMLPackage {
	struct Platform: Decodable {
		let supported: [String]
	}
}
