import Foundation

protocol TOMLTarget {
	var requiresTests: Bool? { get }
	var suitableForDependenciesMatching: Bool? { get }
}
