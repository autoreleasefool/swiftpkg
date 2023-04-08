struct CachedDependencies {
	let dependencies: Set<String>
	let transient: Set<String>
}

extension Context {
	static func resolveTransientDependencies(in targets: [String: Target]) throws {
		var cache: [String: CachedDependencies] = [:]
		for (targetName, target) in targets {
			let transientDependencies = try resolveTransientDependencies(for: targetName, in: targets, cache: &cache)
			if let transient = target.dependencies.intersection(transientDependencies.transient).first,
				 !targetName.starts(with: transient) {
				throw TransientDependencyError(targetName: targetName, dependencyName: transient)
			}

			for transient in transientDependencies.transient {
				target.removeDefault(dependencyOn: transient)
			}
		}
	}

	static func resolveTransientDependencies(
		for targetName: String,
		in targets: [String: Target],
		cache dependencyCache: inout [String: CachedDependencies]
	) throws -> CachedDependencies {
		guard !targetName.starts(with: ".") else { return .init(dependencies: [], transient: []) }

		if let cached = dependencyCache[targetName] {
			return cached
		}

		guard let target = targets[targetName] else {
			throw MissingTargetError(targetName: targetName)
		}

		let dependencies = target.dependencies.union(target.defaultDependencies)
		var transient: Set<String> = []
		for dependency in dependencies {
			let subTransient = try resolveTransientDependencies(for: dependency, in: targets, cache: &dependencyCache)
			transient.formUnion(subTransient.dependencies.union(subTransient.transient))
		}

		let cached = CachedDependencies(dependencies: dependencies, transient: transient)
		dependencyCache[targetName] = cached
		return cached
	}
}
