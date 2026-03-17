import Foundation

/// Runs shell commands in a zsh subprocess and captures output.
struct CommandRunner {

    struct Result {
        let output: String
        let errorOutput: String
        let exitCode: Int32

        var succeeded: Bool { exitCode == 0 }

        var combinedOutput: String {
            var parts: [String] = []
            if !output.isEmpty   { parts.append(output) }
            if !errorOutput.isEmpty { parts.append(errorOutput) }
            return parts.joined(separator: "\n")
        }
    }

    // MARK: - Run

    /// Runs a raw zsh command asynchronously.
    static func run(_ command: String) async -> Result {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/bin/zsh")
                process.arguments = ["-c", command]

                let outPipe = Pipe()
                let errPipe = Pipe()
                process.standardOutput = outPipe
                process.standardError  = errPipe

                do {
                    try process.run()
                    process.waitUntilExit()

                    let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
                    let errData = errPipe.fileHandleForReading.readDataToEndOfFile()

                    continuation.resume(returning: Result(
                        output:      (String(data: outData, encoding: .utf8) ?? "").trimmingCharacters(in: .newlines),
                        errorOutput: (String(data: errData, encoding: .utf8) ?? "").trimmingCharacters(in: .newlines),
                        exitCode:    process.terminationStatus
                    ))
                } catch {
                    continuation.resume(returning: Result(
                        output:      "",
                        errorOutput: error.localizedDescription,
                        exitCode:    -1
                    ))
                }
            }
        }
    }

    /// Runs an alias command — loads .zshrc first so aliases are available.
    static func runAlias(name: String, command: String) async -> Result {
        // Build a command that defines the alias then immediately invokes it
        let cmd = """
        source ~/.zshrc 2>/dev/null; \
        alias \(name)='\(command.replacingOccurrences(of: "'", with: "'\\''"))'; \
        \(name)
        """
        return await run(cmd)
    }

    /// Runs a command directly (no alias wrapping).
    static func runDirect(_ command: String) async -> Result {
        let cmd = "source ~/.zshrc 2>/dev/null; \(command)"
        return await run(cmd)
    }
}
