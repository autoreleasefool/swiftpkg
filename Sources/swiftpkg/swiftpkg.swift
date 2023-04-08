import ArgumentParser
import Foundation
import Stencil
import TOMLKit

@main // swiftlint:disable:next type_name
struct swiftpkg: AsyncParsableCommand {
	@Argument(
		help: "Source directory for the package",
		completion: .file(),
		transform: URL.init(fileURLWithPath:)
	)
	var package: URL

	@Option(
		name: .long,
		help: "Override. A file to import a TOML-defined Package.swift",
		completion: .file(extensions: ["toml"]),
		transform: URL.init(fileURLWithPath:)
	)
	var inputFile: URL?

	@Option(
		name: .long,
		help: "Override. Output file for the Package.swift",
		completion: .file(),
		transform: URL.init(fileURLWithPath:)
	)
	var outputFile: URL?

	@Flag(help: "Analyze package definition for unused dependencies")
	var warnUnusedDependencies: Bool = false

	@Flag(help: "Analyze package definition for missing dependencies")
	var warnMissingDependencies: Bool = false

	mutating func run() async throws {
		let inputFile = self.inputFile ?? package.appending(path: "Package.swift.toml")
		let input = try String(contentsOf: inputFile)

		let table = try TOMLTable(string: input)
		let context = try Context(table)

		if warnUnusedDependencies {
			try context.warnUnusedDependencies(inPackage: package)
		}

		if warnMissingDependencies {
			try context.warnMissingDependencies(inPackage: package)
		}

		let environment = Environment(
			loader: FileSystemLoader(bundle: [Bundle.main, Bundle.module])
		)

		let rendered = try environment.renderTemplate(
			name: "Contents/Resources/Template/Package.swift.stencil",
			context: context.toDictionary()
		)

		let outputFile = self.outputFile ?? package.appending(path: "Package.swift")
		try rendered.data(using: .utf8)?.write(to: outputFile)
	}
}
