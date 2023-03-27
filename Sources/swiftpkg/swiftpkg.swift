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
		help: "Output file for the Package.swift",
		completion: .file(),
		transform: URL.init(fileURLWithPath:)
	)
	var outputFile: URL

	mutating func run() async throws {
		let input = try String(contentsOf: inputFile)
		let package = try TOMLDecoder().decode(TOMLPackage.self, from: input)
		print(package)

		let environment = Environment(
			loader: FileSystemLoader(bundle: [Bundle.main, Bundle.module])
		)

		let context = try Context(package)

		let rendered = try environment.renderTemplate(
			name: "Template/Package.swift.stencil",
			context: context.toDictionary()
		)

		try rendered.data(using: .utf8)?.write(to: outputFile)
	}
}
