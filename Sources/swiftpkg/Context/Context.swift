struct Context {
	let package: PackageDefinition
	let platforms: [(platform: String, supported: [String])]
	let products: [(kind: String, targets: [Target])]

	init(_ package: TOMLPackage) throws {
		self.package = .init(
			name: package.name,
			toolsVersion: package.toolsVersion,
			defaultLocalization: package.defaultLocalization
		)

		self.platforms = package.platforms.map { ($0.key, $0.value.supported) }
		self.products = Target.Kind.allCases.map { ($0.rawValue, []) }
	}

	func toDictionary() -> [String: Any] {
		[
			"package": package,
			"platforms": platforms,
			"products": products,
		]
	}
}
