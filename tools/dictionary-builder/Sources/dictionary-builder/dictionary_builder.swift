import DictionaryBuilderCore
import Foundation

@main
struct DictionaryBuilderMain {
    static func main() {
        do {
            let args = Array(CommandLine.arguments.dropFirst())
            let output = try CommandRunner.run(arguments: args)
            print(output)
        } catch {
            fputs("Error: \(error.localizedDescription)\n", stderr)
            exit(1)
        }
    }
}
