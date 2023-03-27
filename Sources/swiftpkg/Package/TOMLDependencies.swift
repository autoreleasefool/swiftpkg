import Foundation

extension TOMLPackage {
	struct Dependencies: Decodable {
		let url: URL
		let version: Version

		init(from decoder: Decoder) throws {
			let values = try decoder.container(keyedBy: CodingKeys.self)
			guard let url = URL(string: try values.decode(String.self, forKey: .url)) else {
				throw DecodingError.dataCorruptedError(forKey: CodingKeys.url, in: values, debugDescription: "url must be a URL")
			}
			self.url = url

			if values.contains(.branch) {
				let branch = try values.decode(String.self, forKey: .branch)
				self.version = .branch(branch)
			} else if values.contains(.from) {
				let from = try values.decode(String.self, forKey: .from)
				self.version = .from(from)
			} else if values.contains(.revision) {
				let revision = try values.decode(String.self, forKey: .revision)
				self.version = .revision(revision)
			} else {
				throw DecodingError.dataCorruptedError(
					forKey: CodingKeys.from,
					in: values,
					debugDescription: "Missing one of from, revision, or branch"
				)
			}
		}
	}
}

extension TOMLPackage.Dependencies {
	enum Version: CustomStringConvertible {
		case from(String)
		case revision(String)
		case branch(String)

		var description: String {
			switch self {
			case let .from(from):
				return "from: \"\(from)\""
			case let .revision(revision):
				return "revision: \"\(revision)\""
			case let .branch(branch):
				return "branch: \"\(branch)\""
			}
		}
	}
}

extension TOMLPackage.Dependencies {
	enum CodingKeys: String, CodingKey {
		case url
		case from
		case revision
		case branch
	}
}
