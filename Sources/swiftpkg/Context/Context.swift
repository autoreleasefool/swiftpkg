struct Context {
	let package: PackageDefinition
	let platforms: [(platform: String, supported: [String])]
	let dependencies: [Dependency]
	let targets: [Target]
	let products: [(kind: String, products: [TargetDefinition])]

	init(_ package: TOMLPackage) throws {
		self.package = .init(
			name: package.name,
			toolsVersion: package.toolsVersion,
			defaultLocalization: package.defaultLocalization
		)

		self.platforms = package.platforms.map { ($0.key, $0.value.supported) }

		let targets: [Target] = []
		self.targets = targets
		self.products = TargetDefinition.Kind.allCases.map { kind in
			(kind.rawValue, targets.filter { $0.target.kind == kind && $0.target.isProduct }.map(\.target))
		}

		let dependencies: [Dependency] = package.dependencies.map {
			.init(url: $0.value.url, versionString: String(describing: $0.value.version))
		}
		self.dependencies = dependencies.sorted { $0.url.absoluteString < $1.url.absoluteString }

		if self.dependencies != dependencies {
			print("warning: dependencies are not sorted alphabetically")
		}
	}

	func toDictionary() -> [String: Any] {
		[
			"package": package,
			"platforms": platforms,
			"products": products,
			"dependencies": dependencies,
		]
	}
}
