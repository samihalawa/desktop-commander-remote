import Cocoa
import WebKit

// MARK: - Dashboard Window Controller

class DashboardWindowController: NSWindowController, WKNavigationDelegate {
    var webView: WKWebView!
    var toolbar: NSView!
    var urlLabel: NSTextField!
    var spinner: NSProgressIndicator!
    var backButton: NSButton!
    var forwardButton: NSButton!
    var refreshButton: NSButton!

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 640),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "DC Remote — Dashboard"
        window.center()
        window.isReleasedWhenClosed = false
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.minSize = NSSize(width: 600, height: 400)
        window.backgroundColor = NSColor(white: 0.12, alpha: 1)

        self.init(window: window)
        setupUI()
        loadDashboard()
    }

    func setupUI() {
        guard let window = self.window, let contentView = window.contentView else { return }

        // Container
        let container = NSView(frame: contentView.bounds)
        container.autoresizingMask = [.width, .height]
        contentView.addSubview(container)

        // Top toolbar
        toolbar = NSView(frame: NSRect(x: 0, y: contentView.bounds.height - 44, width: contentView.bounds.width, height: 44))
        toolbar.autoresizingMask = [.width, .minYMargin]
        toolbar.wantsLayer = true
        toolbar.layer?.backgroundColor = NSColor(white: 0.15, alpha: 1).cgColor
        container.addSubview(toolbar)

        // Back button
        backButton = makeToolbarButton(title: "\u{25C0}", x: 8)
        backButton.action = #selector(goBack)
        backButton.target = self
        toolbar.addSubview(backButton)

        // Forward button
        forwardButton = makeToolbarButton(title: "\u{25B6}", x: 38)
        forwardButton.action = #selector(goForward)
        forwardButton.target = self
        toolbar.addSubview(forwardButton)

        // Refresh button
        refreshButton = makeToolbarButton(title: "\u{21BB}", x: 68)
        refreshButton.action = #selector(reload)
        refreshButton.target = self
        toolbar.addSubview(refreshButton)

        // URL label
        urlLabel = NSTextField(frame: NSRect(x: 104, y: 10, width: toolbar.bounds.width - 160, height: 24))
        urlLabel.isEditable = false
        urlLabel.isBordered = true
        urlLabel.backgroundColor = NSColor(white: 0.2, alpha: 1)
        urlLabel.textColor = .secondaryLabelColor
        urlLabel.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        urlLabel.cell?.truncatesLastVisibleLine = true
        urlLabel.cell?.lineBreakMode = .byTruncatingMiddle
        urlLabel.stringValue = "mcp.desktopcommander.app"
        urlLabel.autoresizingMask = [.width]
        urlLabel.layer?.cornerRadius = 4
        toolbar.addSubview(urlLabel)

        // Spinner
        spinner = NSProgressIndicator(frame: NSRect(x: toolbar.bounds.width - 36, y: 14, width: 16, height: 16))
        spinner.style = .spinning
        spinner.controlSize = .small
        spinner.autoresizingMask = [.minXMargin]
        spinner.isDisplayedWhenStopped = false
        toolbar.addSubview(spinner)

        // WebView
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        webView = WKWebView(frame: NSRect(x: 0, y: 0, width: contentView.bounds.width, height: contentView.bounds.height - 44), configuration: config)
        webView.autoresizingMask = [.width, .height]
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.setValue(false, forKey: "drawsBackground")
        container.addSubview(webView)
    }

    func makeToolbarButton(title: String, x: CGFloat) -> NSButton {
        let btn = NSButton(frame: NSRect(x: x, y: 8, width: 28, height: 28))
        btn.title = title
        btn.bezelStyle = .recessed
        btn.isBordered = false
        btn.font = NSFont.systemFont(ofSize: 14)
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        btn.attributedTitle = NSAttributedString(string: title, attributes: [
            .foregroundColor: NSColor.secondaryLabelColor,
            .font: NSFont.systemFont(ofSize: 14),
            .paragraphStyle: style
        ])
        return btn
    }

    func loadDashboard() {
        let url = URL(string: "https://mcp.desktopcommander.app")!
        webView.load(URLRequest(url: url))
    }

    @objc func goBack() { webView.goBack() }
    @objc func goForward() { webView.goForward() }
    @objc func reload() { webView.reload() }

    // WKNavigationDelegate
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        spinner.startAnimation(nil)
        backButton.isEnabled = webView.canGoBack
        forwardButton.isEnabled = webView.canGoForward
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        spinner.stopAnimation(nil)
        urlLabel.stringValue = webView.url?.host ?? ""
        backButton.isEnabled = webView.canGoBack
        forwardButton.isEnabled = webView.canGoForward
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        spinner.stopAnimation(nil)
    }

    func showWindow() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - Log Viewer Window

class LogViewerWindowController: NSWindowController, NSWindowDelegate {
    var textView: NSTextView!
    var scrollView: NSScrollView!
    var refreshTimer: Timer?
    let logPath = NSHomeDirectory() + "/.desktop-commander-device/device.log"

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: 480),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "DC Remote — Logs"
        window.center()
        window.isReleasedWhenClosed = false
        window.titlebarAppearsTransparent = true
        window.backgroundColor = NSColor(white: 0.1, alpha: 1)

        self.init(window: window)
        setupUI()
    }

    func setupUI() {
        guard let contentView = window?.contentView else { return }

        // Delegate must be set for windowWillClose to fire and stop the refresh timer
        window?.delegate = self

        // Toolbar
        let toolbar = NSView(frame: NSRect(x: 0, y: contentView.bounds.height - 36, width: contentView.bounds.width, height: 36))
        toolbar.autoresizingMask = [.width, .minYMargin]
        toolbar.wantsLayer = true
        toolbar.layer?.backgroundColor = NSColor(white: 0.13, alpha: 1).cgColor
        contentView.addSubview(toolbar)

        let clearBtn = NSButton(frame: NSRect(x: 8, y: 4, width: 60, height: 28))
        clearBtn.title = "Clear"
        clearBtn.bezelStyle = .recessed
        clearBtn.target = self
        clearBtn.action = #selector(clearLogs)
        toolbar.addSubview(clearBtn)

        let tailLabel = NSTextField(labelWithString: "Auto-refresh: 2s")
        tailLabel.frame = NSRect(x: toolbar.bounds.width - 130, y: 8, width: 120, height: 20)
        tailLabel.textColor = .tertiaryLabelColor
        tailLabel.font = NSFont.systemFont(ofSize: 10)
        tailLabel.autoresizingMask = [.minXMargin]
        toolbar.addSubview(tailLabel)

        // ScrollView + TextView
        scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: contentView.bounds.width, height: contentView.bounds.height - 36))
        scrollView.autoresizingMask = [.width, .height]
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false

        textView = NSTextView(frame: scrollView.bounds)
        textView.isEditable = false
        textView.isSelectable = true
        textView.backgroundColor = NSColor(white: 0.1, alpha: 1)
        textView.textColor = NSColor(white: 0.8, alpha: 1)
        textView.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        textView.autoresizingMask = [.width]
        textView.textContainerInset = NSSize(width: 8, height: 8)

        scrollView.documentView = textView
        contentView.addSubview(scrollView)

        loadLogs()
    }

    // Reads only the trailing bytes of the log. device.log grows unbounded (70MB+),
    // so reading it whole blocked the main thread for ~0.7s on every 2s refresh.
    func readLogTail(maxBytes: UInt64 = 64_000) -> String {
        guard let handle = try? FileHandle(forReadingFrom: URL(fileURLWithPath: logPath)) else {
            return "No logs found."
        }
        defer { try? handle.close() }

        let size = (try? handle.seekToEnd()) ?? 0
        let offset = size > maxBytes ? size - maxBytes : 0
        try? handle.seek(toOffset: offset)
        let data = (try? handle.readToEnd()) ?? Data()

        var text = String(decoding: data, as: UTF8.self)
        // Seeking mid-file usually lands inside a line; drop the partial first one
        if offset > 0, let newline = text.firstIndex(of: "\n") {
            text = String(text[text.index(after: newline)...])
        }
        return text
    }

    func loadLogs() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            let lines = self.readLogTail().components(separatedBy: "\n")
            let tail = lines.suffix(200).joined(separator: "\n")
            let attributed = self.colorize(tail)

            DispatchQueue.main.async {
                guard let textView = self.textView else { return }
                textView.textStorage?.setAttributedString(attributed)
                textView.scrollToEndOfDocument(nil)
            }
        }
    }

    func colorize(_ text: String) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let defaultAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular),
            .foregroundColor: NSColor(white: 0.75, alpha: 1)
        ]
        for line in text.components(separatedBy: "\n") {
            var attrs = defaultAttrs
            if line.contains("\u{2705}") || line.contains("successful") || line.contains("ready") || line.contains("Online") {
                attrs[.foregroundColor] = NSColor.systemGreen
            } else if line.contains("\u{274C}") || line.contains("error") || line.contains("Error") || line.contains("failed") {
                attrs[.foregroundColor] = NSColor.systemRed
            } else if line.contains("\u{26A0}") || line.contains("warning") || line.contains("Warning") {
                attrs[.foregroundColor] = NSColor.systemYellow
            } else if line.contains("[DEBUG]") {
                attrs[.foregroundColor] = NSColor(white: 0.45, alpha: 1)
            } else if line.contains("\u{1F680}") || line.contains("\u{1F50C}") || line.contains("\u{231B}") {
                attrs[.foregroundColor] = NSColor.systemCyan
            }
            result.append(NSAttributedString(string: line + "\n", attributes: attrs))
        }
        return result
    }

    @objc func clearLogs() {
        try? "".write(toFile: logPath, atomically: true, encoding: .utf8)
        textView.string = ""
    }

    func showWindow() {
        loadLogs()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            self?.loadLogs()
        }
    }

    func windowWillClose(_ notification: Notification) {
        refreshTimer?.invalidate()
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var timer: Timer?
    var dashboardController: DashboardWindowController?
    var logController: LogViewerWindowController?
    let launchAgentLabel = "com.desktopcommander.remote-device"
    let configPath = NSHomeDirectory() + "/.desktop-commander-device/device.json"
    let preferredDeviceName = "mac4"

    var deviceConfig: [String: Any]? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: configPath)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return json
    }

    var deviceId: String {
        guard let id = deviceConfig?["deviceId"] as? String else { return "unknown" }
        return id
    }

    var deviceName: String {
        if let configured = deviceConfig?["deviceName"] as? String, !configured.isEmpty {
            return configured
        }
        return preferredDeviceName
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateStatus()
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.updateStatus()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    func updateStatus() {
        // isRunning() spawns launchctl and blocks on waitUntilExit(); keep it off the main thread
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            let running = self.isRunning()
            DispatchQueue.main.async {
                guard let button = self.statusItem.button else { return }
                button.image = self.createMenuBarIcon(online: running)
                button.title = ""
                button.toolTip = running ? "DC Remote: Online" : "DC Remote: Offline"
                self.buildMenu(running: running)
            }
        }
    }

    func createMenuBarIcon(online: Bool) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)
        image.lockFocus()

        let monitorColor: NSColor = .labelColor
        monitorColor.setStroke()

        let screenRect = NSRect(x: 2, y: 5, width: 14, height: 10)
        let screenPath = NSBezierPath(roundedRect: screenRect, xRadius: 1.5, yRadius: 1.5)
        screenPath.lineWidth = 1.2
        screenPath.stroke()

        let standPath = NSBezierPath()
        standPath.move(to: NSPoint(x: 7, y: 5))
        standPath.line(to: NSPoint(x: 7, y: 3))
        standPath.move(to: NSPoint(x: 11, y: 5))
        standPath.line(to: NSPoint(x: 11, y: 3))
        standPath.move(to: NSPoint(x: 5, y: 3))
        standPath.line(to: NSPoint(x: 13, y: 3))
        standPath.lineWidth = 1.2
        standPath.stroke()

        let dotColor: NSColor = online ? .systemGreen : .systemRed
        dotColor.setFill()
        NSBezierPath(ovalIn: NSRect(x: 7, y: 8, width: 4, height: 4)).fill()

        image.unlockFocus()
        image.isTemplate = false
        return image
    }

    func isRunning() -> Bool {
        let task = Process()
        task.launchPath = "/bin/launchctl"
        task.arguments = ["list", launchAgentLabel]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
        do {
            try task.run()
            task.waitUntilExit()
            if task.terminationStatus != 0 { return false }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            return output.contains("\"PID\"") && !output.contains("\"PID\" = 0;")
        } catch {
            return false
        }
    }

    func buildMenu(running: Bool) {
        let menu = NSMenu()

        // Header
        let header = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        header.attributedTitle = NSAttributedString(string: "Desktop Commander Remote", attributes: [
            .font: NSFont.boldSystemFont(ofSize: 13)
        ])
        header.isEnabled = false
        menu.addItem(header)

        // Status line
        let statusText = running ? "Online — \(deviceName)" : "Offline"
        let statusColor: NSColor = running ? .systemGreen : .systemRed
        let statusMenuItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        statusMenuItem.attributedTitle = NSAttributedString(string: "  \u{25CF} " + statusText, attributes: [
            .foregroundColor: statusColor,
            .font: NSFont.systemFont(ofSize: 12)
        ])
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)

        if running {
            let idText = "  ID: " + String(deviceId.prefix(8)) + "..."
            let idItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
            idItem.attributedTitle = NSAttributedString(string: idText, attributes: [
                .foregroundColor: NSColor.tertiaryLabelColor,
                .font: NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
            ])
            idItem.isEnabled = false
            menu.addItem(idItem)
        }

        menu.addItem(NSMenuItem.separator())

        // Dashboard
        let dashboard = NSMenuItem(title: "Dashboard", action: #selector(openDashboard), keyEquivalent: "d")
        dashboard.target = self
        menu.addItem(dashboard)

        // Logs
        let logs = NSMenuItem(title: "Logs", action: #selector(openLogs), keyEquivalent: "l")
        logs.target = self
        menu.addItem(logs)

        menu.addItem(NSMenuItem.separator())

        // Controls
        if running {
            let restart = NSMenuItem(title: "Restart", action: #selector(restartDevice), keyEquivalent: "r")
            restart.target = self
            menu.addItem(restart)

            let stop = NSMenuItem(title: "Stop", action: #selector(stopDevice), keyEquivalent: "")
            stop.target = self
            menu.addItem(stop)
        } else {
            let start = NSMenuItem(title: "Start", action: #selector(startDevice), keyEquivalent: "s")
            start.target = self
            menu.addItem(start)
        }

        menu.addItem(NSMenuItem.separator())

        let copyId = NSMenuItem(title: "Copy Device ID", action: #selector(copyDeviceId), keyEquivalent: "c")
        copyId.target = self
        menu.addItem(copyId)

        menu.addItem(NSMenuItem.separator())

        let quit = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        self.statusItem.menu = menu
    }

    // MARK: - Actions

    @objc func openDashboard() {
        if dashboardController == nil {
            dashboardController = DashboardWindowController()
        }
        dashboardController?.showWindow()
    }

    @objc func openLogs() {
        if logController == nil {
            logController = LogViewerWindowController()
        }
        logController?.showWindow()
    }

    var plistPath: String {
        NSHomeDirectory() + "/Library/LaunchAgents/\(launchAgentLabel).plist"
    }

    @objc func startDevice() {
        runLaunchctl(["bootstrap", "gui/\(getuid())", plistPath], action: "start", settleDelay: 3)
    }

    @objc func stopDevice() {
        runLaunchctl(["bootout", "gui/\(getuid())", plistPath], action: "stop", settleDelay: 2)
    }

    @objc func restartDevice() {
        stopDevice()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.startDevice()
        }
    }

    // launchctl failures used to be swallowed silently, so a failed Start looked
    // identical to a successful one and the menu just stayed on "Offline".
    func runLaunchctl(_ args: [String], action: String, settleDelay: Double) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let result = self.runShell("/bin/launchctl", args)
            DispatchQueue.main.async {
                if result.status != 0 {
                    self.reportFailure(action: action, result: result)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + settleDelay) {
                    self.updateStatus()
                }
            }
        }
    }

    func reportFailure(action: String, result: (status: Int32, output: String)) {
        var detail = result.output.trimmingCharacters(in: .whitespacesAndNewlines)
        if detail.isEmpty {
            detail = "launchctl exited with status \(result.status)."
        }
        // Name the two non-obvious causes explicitly instead of leaving a bare errno
        if !FileManager.default.fileExists(atPath: plistPath) {
            detail += "\n\nThe LaunchAgent file is missing:\n\(plistPath)"
        } else if result.status == 5 {
            detail += "\n\nThe service may be disabled in launchd. Try:\n"
                + "launchctl enable gui/\(getuid())/\(launchAgentLabel)"
        }

        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Could not \(action) the device"
        alert.informativeText = detail
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Copy Details")
        NSApp.activate(ignoringOtherApps: true)
        if alert.runModal() == .alertSecondButtonReturn {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(detail, forType: .string)
        }
    }

    @objc func copyDeviceId() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(deviceId, forType: .string)
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    @discardableResult
    func runShell(_ path: String, _ args: [String]) -> (status: Int32, output: String) {
        let task = Process()
        task.launchPath = path
        task.arguments = args
        let errorPipe = Pipe()
        task.standardOutput = Pipe()
        task.standardError = errorPipe
        do {
            try task.run()
        } catch {
            return (-1, "Failed to launch \(path): \(error.localizedDescription)")
        }
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()
        return (task.terminationStatus, String(data: errorData, encoding: .utf8) ?? "")
    }
}

// MARK: - Main

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
