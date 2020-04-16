
import ArgumentParser
import Foundation

struct Lox: ParsableCommand {

    static let configuration = CommandConfiguration(commandName: "slox")

    @Argument(help: "The lox file to read in.")
    var file: String?

    func run() throws {

        if let file = file {
            try runFile(file)
        } else {
            try runPrompt()
        }
    }

    func runFile(_ file: String) throws {

        guard let directory = Process().currentDirectoryURL else {
            struct NoCurrentDirectoryURL: Error {}
            throw NoCurrentDirectoryURL()
        }

        let url = directory.appendingPathComponent(file)
        let code = try String(contentsOf: url)
        try runCode(code)
    }

    func runPrompt() throws {

        print("> ")

        while let line = readLine() {
            try runCode(line)
            print("> ")
        }
    }

    func runCode(_ code: String) throws {
        print("Running \(code)")
    }
}
