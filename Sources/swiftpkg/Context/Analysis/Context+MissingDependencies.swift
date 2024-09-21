import Foundation

extension Context {
	func warnMissingDependencies(inPackage packageURL: URL) throws {
		var cache: [String: CachedDependencies] = [:]
		for (targetName, target) in targets {
			guard target.definition.qualifier != .test else { continue }

			let dependencies = try Self.resolveTransientDependencies(for: targetName, in: targets, cache: &cache)
			let transientDependencies = Set(
				dependencies.dependencies
					.union(dependencies.transient)
					.union(target.defaultDependencies).map {
						if $0.starts(with: ".") {
							return String($0.firstMatch(of: productRegex)?.1 ?? "")
						} else {
							return $0
						}
					}
			)
			let usedDependencies = try Self.findUsedDependencies(inPackage: packageURL, forTarget: targetName)
				.subtracting(Self.ignoredDependencies)

			let missingDependencies = usedDependencies.subtracting(transientDependencies)

			if let missingDependency = missingDependencies.first {
				throw MissingDependencyError(
					targetName: targetName,
					missingDependency: missingDependency
				)
			}
		}
	}
}
