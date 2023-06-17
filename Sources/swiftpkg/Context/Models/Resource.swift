import Foundation
import TOMLKit

struct Resource: CustomStringConvertible {
	let name: String
	let rule: Rule

	init(name: String, rule: Rule) {
		self.name = name
		self.rule = rule
	}

	var description: String {
		switch rule {
		case .copy: return ".copy(\"\(name)\")"
		case .process: return ".process(\"\(name)\")"
		}
	}
}

extension Resource {
	enum Rule {
		case process
		case copy
	}
}
