import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var statusMenuItem: NSMenuItem!
    private var fullStatusText = ""

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = makeStatusIcon()
        statusItem.button?.imagePosition = .imageLeading
        statusItem.button?.title = "--/--"

        let menu = NSMenu()
        statusMenuItem = NSMenuItem(title: "Loading…", action: nil, keyEquivalent: "")
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)
        menu.addItem(.separator())
        menu.addItem(withTitle: "Refresh", action: #selector(refresh), keyEquivalent: "r")
        menu.addItem(withTitle: "Quit", action: #selector(quit), keyEquivalent: "q")
        statusItem.menu = menu

        updateStatus()
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.updateStatus()
        }
    }

    func updateStatus() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self else { return }

            let scriptURL = Bundle.main.executableURL!
                .deletingLastPathComponent()
                .appendingPathComponent("codex-status-script.sh")

            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = ["bash", scriptURL.path]

            let pipe = Pipe()
            process.standardOutput = pipe

            var compactTitle = "ERR"
            var detailTitle = "Status unavailable"
            do {
                try process.run()
                process.waitUntilExit()

                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8)?
                    .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

                if process.terminationStatus == 0, !output.isEmpty,
                   let parsed = Self.parseStatus(output) {
                    self.fullStatusText = output
                    compactTitle = parsed.compact
                    detailTitle = parsed.detail
                }
            } catch {}

            DispatchQueue.main.async {
                self.statusItem.button?.title = compactTitle
                self.statusMenuItem.title = detailTitle
            }
        }
    }

    private static func parseStatus(_ output: String) -> (compact: String, detail: String)? {
        guard let five = captureGroups(in: output, pattern: #"5h:\s*(\d+)%\s*\(([^)]+)\)"#),
              let weekly = captureGroups(in: output, pattern: #"Weekly:\s*(\d+)%\s*\(([^)]+)\)"#),
              let credits = captureGroups(in: output, pattern: #"Credits:\s*(\S+)"#) else {
            return nil
        }

        let compact = "\(five[0])/\(weekly[0])"
        let detail = """
        5h: \(five[0])% (\(five[1]))
        Weekly: \(weekly[0])% (\(weekly[1]))
        Credits: \(credits[0])
        """
        return (compact, detail)
    }

    private static func captureGroups(in string: String, pattern: String) -> [String]? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: string, range: NSRange(string.startIndex..., in: string)),
              match.numberOfRanges > 1 else {
            return nil
        }

        return (1..<match.numberOfRanges).compactMap { index in
            guard let range = Range(match.range(at: index), in: string) else { return nil }
            return String(string[range])
        }
    }

    private func makeStatusIcon() -> NSImage {
        let side: CGFloat = 16
        let image = NSImage(size: NSSize(width: side, height: side), flipped: false) { rect in
            let center = NSPoint(x: rect.midX, y: rect.midY)
            let radius = (min(rect.width, rect.height) - 4) / 2
            let path = NSBezierPath()

            for i in 0..<6 {
                let angle = CGFloat.pi / 3 * CGFloat(i) - CGFloat.pi / 6
                let point = NSPoint(
                    x: center.x + radius * cos(angle),
                    y: center.y + radius * sin(angle)
                )
                if i == 0 {
                    path.move(to: point)
                } else {
                    path.line(to: point)
                }
            }
            path.close()
            NSColor.black.setFill()
            path.fill()
            return true
        }
        image.isTemplate = true
        return image
    }

    @objc private func refresh() {
        updateStatus()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

}

@main
struct Main {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}

