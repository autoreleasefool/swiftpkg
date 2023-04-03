import Foundation

struct UnsupportedTargetDependencyError: Error, LocalizedError {
	let targetName: String
	let targetKind: TargetDefinition.Kind
	let dependencyName: String
	let dependencyKind: TargetDefinition.Kind

	var errorDescription: String? {
		return "Target \(targetName) of kind \(targetKind) cannot depend on \(dependencyName) of kind \(dependencyKind)"
	}
}
