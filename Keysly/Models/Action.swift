import Foundation

// MARK: - Script Type

enum ScriptType: String, Codable, CaseIterable, Hashable, Sendable {
    case shell = "Shell"
    case appleScript = "AppleScript"
    case jxa = "JavaScript for Automation"
}

// MARK: - System Action Type

enum SystemActionType: String, Codable, CaseIterable, Hashable, Sendable {
    case sleep = "Sleep"
    case lock = "Lock Screen"
    case logout = "Log Out"
    case toggleDarkMode = "Toggle Dark Mode"
    case emptyTrash = "Empty Trash"
    case showDesktop = "Show Desktop"
    case missionControl = "Mission Control"
    case launchpad = "Launchpad"
    case notification = "Show Notification Center"
    
    var iconName: String {
        switch self {
        case .sleep: return "moon.fill"
        case .lock: return "lock.fill"
        case .logout: return "rectangle.portrait.and.arrow.right"
        case .toggleDarkMode: return "circle.lefthalf.filled"
        case .emptyTrash: return "trash.fill"
        case .showDesktop: return "menubar.dock.rectangle"
        case .missionControl: return "rectangle.3.group"
        case .launchpad: return "square.grid.3x3"
        case .notification: return "bell.fill"
        }
    }
}

// MARK: - Action

enum Action: Codable, Hashable, Sendable {
    case launchApp(bundleId: String, appName: String)
    case openURL(url: URL, name: String?)
    case runScript(path: String, type: ScriptType)
    case runInlineScript(script: String, type: ScriptType)
    case systemAction(SystemActionType)
    case runShortcut(name: String)
    case typeText(text: String, name: String)
    case chain([Action])
    
    var displayName: String {
        switch self {
        case .launchApp(_, let name): return "Open \(name)"
        case .openURL(let url, let name): return name ?? url.host ?? url.absoluteString
        case .runScript(let path, _): return "Run \(URL(fileURLWithPath: path).lastPathComponent)"
        case .runInlineScript(_, let type): return "Run \(type.rawValue)"
        case .systemAction(let type): return type.rawValue
        case .runShortcut(let name): return "Shortcut: \(name)"
        case .typeText(_, let name): return name.isEmpty ? "Type Text" : "Type: \(name)"
        case .chain(let actions): return "\(actions.count) actions"
        }
    }
    
    var iconName: String {
        switch self {
        case .launchApp: return "app.fill"
        case .openURL: return "globe"
        case .runScript, .runInlineScript: return "terminal.fill"
        case .systemAction(let type): return type.iconName
        case .runShortcut: return "bolt.fill"
        case .typeText: return "text.cursor"
        case .chain: return "link"
        }
    }
}
