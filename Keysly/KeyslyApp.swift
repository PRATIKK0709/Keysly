import SwiftUI
import AppKit

// MARK: - App

@main
struct KeyslyApp: App {
    
    @State private var appState = AppState()
    @AppStorage("selectedTheme") private var selectedTheme = "system"
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showOnboarding = false
    
    var body: some Scene {
        // Main window
        WindowGroup {
            ContentView()
                .environment(appState)
                .preferredColorScheme(colorScheme)
                .sheet(isPresented: $showOnboarding) {
                    OnboardingView(isPresented: $showOnboarding)
                        .environment(appState)
                        .preferredColorScheme(colorScheme)
                }
                .onAppear {
                    if !hasCompletedOnboarding {
                        showOnboarding = true
                        hasCompletedOnboarding = true
                    }
                }
        }
        .windowResizability(.contentSize)
        
        // Settings window
        Settings {
            SettingsView()
                .environment(appState)
                .preferredColorScheme(colorScheme)
        }
    }
    
    private var colorScheme: ColorScheme? {
        switch selectedTheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
}

// MARK: - App State

@Observable
@MainActor
final class AppState: KeyboardMonitorDelegate {
    
    let shortcutStore = ShortcutStore()
    let permissionManager = PermissionManager()
    let keyboardMonitor: KeyboardMonitor
    
    var pendingKeyCombo: KeyCombo?
    var showingAssignmentPrompt = false
    var showingKeyCaptureOverlay = false
    
    init() {
        keyboardMonitor = KeyboardMonitor(shortcutStore: shortcutStore)
        keyboardMonitor.delegate = self
        
        // Start monitoring if permissions are ready
        if permissionManager.isFullyReady {
            keyboardMonitor.start()
        }
        
        // Watch for permission changes
        Task {
            while true {
                try? await Task.sleep(for: .seconds(1))
                if permissionManager.isFullyReady && !keyboardMonitor.isMonitoring {
                    keyboardMonitor.start()
                }
            }
        }
    }
    
    // MARK: - KeyboardMonitorDelegate
    
    nonisolated func keyboardMonitor(_ monitor: KeyboardMonitor, didCaptureUnknownCombo keyCombo: KeyCombo) {
        Task { @MainActor in
            self.pendingKeyCombo = keyCombo
            self.showingAssignmentPrompt = true
            
            // Open the assignment window
            if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "assign-shortcut" }) {
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
    
    nonisolated func keyboardMonitor(_ monitor: KeyboardMonitor, didTriggerShortcut shortcut: Shortcut) {
        Task { @MainActor in
            // Record the use
            self.shortcutStore.recordUse(id: shortcut.id)
            
            // Execute the action
            do {
                try await ActionExecutor.shared.execute(shortcut.action)
            } catch {
                // Show error notification
                print("Failed to execute shortcut: \(error)")
            }
        }
    }
    
    // MARK: - Actions
    
    func saveShortcut(keyCombo: KeyCombo, action: Action) {
        let shortcut = Shortcut(keyCombo: keyCombo, action: action)
        try? shortcutStore.addShortcut(shortcut)
        pendingKeyCombo = nil
        showingAssignmentPrompt = false
    }
    
    func cancelAssignment() {
        pendingKeyCombo = nil
        showingAssignmentPrompt = false
    }
}
