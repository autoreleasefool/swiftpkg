struct Context {
	let package: PackageDefinition
	let platforms: [String: Platform]

	init(_ package: TOMLPackage) throws {
		self.package = .init(
			name: package.name,
			toolsVersion: package.toolsVersion,
			defaultLocalization: package.defaultLocalization
		)

		self.platforms = Dictionary(
			uniqueKeysWithValues: package.platforms.map { ($0.key, .init(supported: $0.value.supported)) }
		)
	}

	func toDictionary() -> [String: Any] {
		[
			"package": package,
			"platforms": platforms,
		]
	}
}
