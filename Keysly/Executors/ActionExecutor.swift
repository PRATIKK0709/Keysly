import Foundation
import AppKit
import Carbon.HIToolbox

// MARK: - Action Executor Protocol

protocol ActionExecutorProtocol: Sendable {
    func execute(_ action: Action) async throws
}

// MARK: - Action Executor

actor ActionExecutor: ActionExecutorProtocol {
    
    static let shared = ActionExecutor()
    
    func execute(_ action: Action) async throws {
        switch action {
        case .launchApp(let bundleId, _):
            try await launchApp(bundleId: bundleId)
            
        case .openURL(let url, _):
            try await openURL(url)
            
        case .runScript(let path, let type):
            try await runScript(at: path, type: type)
            
        case .runInlineScript(let script, let type):
            try await runInlineScript(script, type: type)
            
        case .systemAction(let actionType):
            try await executeSystemAction(actionType)
            
        case .runShortcut(let name):
            try await ShortcutsService.shared.run(shortcut: name)
            
        case .typeText(let text, _):
            try await typeText(text)
            
        case .chain(let actions):
            for action in actions {
                try await execute(action)
            }
        }
    }
    
    // MARK: - App Launch
    
    private func launchApp(bundleId: String) async throws {
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) else {
            throw ExecutorError.appNotFound(bundleId)
        }
        
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        
        try await NSWorkspace.shared.openApplication(at: appURL, configuration: configuration)
    }
    
    // MARK: - URL
    
    private func openURL(_ url: URL) async throws {
        let success = NSWorkspace.shared.open(url)
        if !success {
            throw ExecutorError.urlOpenFailed(url)
        }
    }
    
    // MARK: - Scripts
    
    private func runScript(at path: String, type: ScriptType) async throws {
        let script = try String(contentsOfFile: path, encoding: .utf8)
        try await runInlineScript(script, type: type)
    }
    
    private func runInlineScript(_ script: String, type: ScriptType) async throws {
        switch type {
        case .shell:
            try await runShellScript(script)
        case .appleScript:
            try await runAppleScript(script)
        case .jxa:
            try await runJXA(script)
        }
    }
    
    private func runShellScript(_ script: String) async throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", script]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw ExecutorError.scriptFailed(output)
        }
    }
    
    private func runAppleScript(_ script: String) async throws {
        var error: NSDictionary?
        let appleScript = NSAppleScript(source: script)
        appleScript?.executeAndReturnError(&error)
        
        if let error = error {
            throw ExecutorError.scriptFailed(error.description)
        }
    }
    
    private func runJXA(_ script: String) async throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-l", "JavaScript", "-e", script]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw ExecutorError.scriptFailed(output)
        }
    }
    
    // MARK: - Text Expansion (Pasteboard-based for reliability)
    
    private func typeText(_ text: String) async throws {
        print("[TypeText] Starting text expansion...")
        print("[TypeText] Text to type: \"\(text)\" (\(text.count) chars)")
        
        // Save current pasteboard content
        let pasteboard = NSPasteboard.general
        let previousContent = pasteboard.string(forType: .string)
        print("[TypeText] Saved previous clipboard: \(previousContent != nil ? "yes" : "no")")
        
        // Set our text to pasteboard
        pasteboard.clearContents()
        let setResult = pasteboard.setString(text, forType: .string)
        print("[TypeText] Set clipboard result: \(setResult)")
        
        // Verify pasteboard content
        if let clipboardText = pasteboard.string(forType: .string) {
            print("[TypeText] Clipboard now contains: \"\(clipboardText.prefix(50))...\"")
        } else {
            print("[TypeText] ERROR: Clipboard is empty after setting!")
        }
        
        // Small delay to ensure pasteboard is ready
        try await Task.sleep(for: .milliseconds(100))
        
        // Simulate Cmd+V to paste
        let source = CGEventSource(stateID: .combinedSessionState)
        print("[TypeText] CGEventSource created: \(source != nil ? "yes" : "no")")
        
        if source == nil {
            print("[TypeText] WARNING: CGEventSource is nil - accessibility permissions may be missing!")
        }
        
        // Key down for V with Command modifier
        if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: UInt16(kVK_ANSI_V), keyDown: true) {
            keyDown.flags = .maskCommand
            keyDown.post(tap: .cgAnnotatedSessionEventTap)
            print("[TypeText] Posted Cmd+V key down")
        } else {
            print("[TypeText] ERROR: Failed to create keyDown event!")
        }
        
        // Small delay
        try await Task.sleep(for: .milliseconds(50))
        
        // Key up for V
        if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: UInt16(kVK_ANSI_V), keyDown: false) {
            keyUp.flags = .maskCommand
            keyUp.post(tap: .cgAnnotatedSessionEventTap)
            print("[TypeText] Posted Cmd+V key up")
        } else {
            print("[TypeText] ERROR: Failed to create keyUp event!")
        }
        
        // Wait for paste to complete
        try await Task.sleep(for: .milliseconds(150))
        print("[TypeText] Paste delay completed")
        
        // Restore previous pasteboard content
        if let previousContent = previousContent {
            pasteboard.clearContents()
            pasteboard.setString(previousContent, forType: .string)
            print("[TypeText] Restored previous clipboard content")
        }
        
        print("[TypeText] Text expansion complete!")
    }
    
    // MARK: - System Actions
    
    private func executeSystemAction(_ actionType: SystemActionType) async throws {
        switch actionType {
        case .sleep:
            try await runShellScript("pmset sleepnow")
            
        case .lock:
            try await runShellScript("open -a ScreenSaverEngine")
            
        case .logout:
            try await runShellScript("osascript -e 'tell application id \"com.apple.systemevents\" to log out'")
            
        case .toggleDarkMode:
            try await runShellScript("""
                osascript -e 'tell application id "com.apple.systemevents" to tell appearance preferences to set dark mode to not dark mode'
            """)
            
        case .emptyTrash:
            try await runShellScript("osascript -e 'tell application id \"com.apple.finder\" to empty trash'")
            
        case .showDesktop:
            try await runShellScript("open -a 'Mission Control' --args --toggle-show-desktop")
            
        case .missionControl:
            try await runShellScript("open -a 'Mission Control'")
            
        case .launchpad:
            try await runShellScript("open -a Launchpad")
            
        case .notification:
            try await runShellScript("open -g 'x-apple.systempreferences:com.apple.preference.notifications'")
        }
    }
}

// MARK: - Errors

enum ExecutorError: LocalizedError {
    case appNotFound(String)
    case urlOpenFailed(URL)
    case scriptFailed(String)
    case textTypingFailed
    case unsupportedAction
    
    var errorDescription: String? {
        switch self {
        case .appNotFound(let bundleId):
            return "Application not found: \(bundleId)"
        case .urlOpenFailed(let url):
            return "Failed to open URL: \(url)"
        case .scriptFailed(let message):
            return "Script failed: \(message)"
        case .textTypingFailed:
            return "Failed to type text"
        case .unsupportedAction:
            return "This action is not supported"
        }
    }
}
