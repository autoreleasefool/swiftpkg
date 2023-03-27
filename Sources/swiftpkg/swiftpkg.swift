import ArgumentParser
import Foundation

@main
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
	var ouputFile: URL

	mutating func run() async throws {
		let input = try String(contentsOf: inputFile)
	}
}
