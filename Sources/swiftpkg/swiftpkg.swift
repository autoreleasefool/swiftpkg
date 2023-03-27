@main
public struct swiftpkg {
	public private(set) var text = "Hello, World!"
	
	public static func main() {
		print(swiftpkg().text)
	}
}
