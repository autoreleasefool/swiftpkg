import ArgumentParser
import Foundation
import Stencil
import TOMLKit

@main // swiftlint:disable:next type_name
struct swiftpkg: AsyncParsableCommand {
	@Argument(
		help: "A file to import a TOML-defined Package.swift",
		completion: .file(extensions: ["toml"]),
		transform: URL.init(fileURLWithPath:)
	)
	var inputFile: URL

	@Argument(
		help: "Path where the package lives",
		completion: .file(),
		transform: URL.init(fileURLWithPath:)
	)
	var packageSource: URL

	@Option(
		name: .long,
		help: "Output file for the Package.swift",
		completion: .file(),
		transform: URL.init(fileURLWithPath:)
	)
	var outputFile: URL?

	@Flag(help: "Analyze package definition for unused dependencies")
	var warnUnusedDependencies: Bool = false

	@Flag(help: "Analyze package definition for missing dependencies")
	var warnMissingDependencies: Bool = false

	mutating func run() async throws {
		let input = try String(contentsOf: inputFile)

		let table = try TOMLTable(string: input)
		let context = try Context(table)

		if warnUnusedDependencies {
			try context.warnUnusedDependencies(inPackage: packageSource)
		}

		if warnMissingDependencies {
			try context.warnMissingDependencies(inPackage: packageSource)
		}

		let environment = Environment(
			loader: FileSystemLoader(bundle: [Bundle.main, Bundle.module])
		)

		let rendered = try environment.renderTemplate(
			name: "Contents/Resources/Template/Package.swift.stencil",
			context: context.toDictionary()
		)

		let outputFile = self.outputFile ?? packageSource.appending(path: "Package.swift")
		try rendered.data(using: .utf8)?.write(to: outputFile)
	}
}
