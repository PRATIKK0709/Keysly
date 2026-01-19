import SwiftUI

// MARK: - Navigation Item
enum NavigationItem: String, CaseIterable {
    case shortcuts = "Shortcuts"
    case wiki = "Wiki"
    case settings = "Settings"
    
    var icon: String {
        switch self {
        case .shortcuts: return "command"
        case .wiki: return "book"
        case .settings: return "gearshape"
        }
    }
}

struct ContentView: View {
    
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedItem: NavigationItem = .shortcuts
    @State private var isRecording = false
    @State private var recordedKeyCombo: KeyCombo?
    @State private var showingAssignment = false
    @State private var editingShortcut: Shortcut?
    @State private var conflictError: String?
    @State private var shortcutToDelete: Shortcut?
    @State private var eventMonitor: Any?
    
    // Theme Colors (Adaptive)
    private var bgPrimary: Color {
        colorScheme == .dark ? Color(hex: 0x1C1C1E) : Color(hex: 0xFFFFFF)
    }
    private var bgSecondary: Color {
        colorScheme == .dark ? Color(hex: 0x2C2C2E) : Color(hex: 0xF5F5F7)
    }
    private var bgTertiary: Color {
        colorScheme == .dark ? Color(hex: 0x3A3A3C) : Color(hex: 0xE5E5EB)
    }
    private var textPrimary: Color {
        colorScheme == .dark ? .white : Color(hex: 0x000000)
    }
    private var textSecondary: Color {
        colorScheme == .dark ? Color(hex: 0x8E8E93) : Color(hex: 0x6E6E73)
    }
    private var accentColor: Color {
        Color(hex: 0xFF9500)
    }
    
    var body: some View {
        ZStack {
            bgPrimary.ignoresSafeArea()
            
            HStack(spacing: 0) {
                // Sidebar
                sidebar
                    .frame(width: 200)
                    .background(bgSecondary)
                    .overlay(
                        Rectangle()
                            .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                            .frame(width: 1),
                        alignment: .trailing
                    )
                
                // Main Content
                VStack(spacing: 0) {
                    if selectedItem == .shortcuts && !appState.permissionManager.isFullyReady {
                        permissionsNeeded
                    } else if isRecording {
                        recordingOverlay
                    } else if showingAssignment, let keyCombo = recordedKeyCombo {
                        assignmentOverlay(keyCombo: keyCombo)
                    } else {
                        mainContent
                    }
                }
            }
        }
        .frame(width: 1000, height: 700)
        // .preferredColorScheme(.light) removed to allow system/app override
        // Alerts
        .alert("Shortcut Conflict", isPresented: .init(
            get: { conflictError != nil },
            set: { if !$0 { conflictError = nil } }
        )) {
            Button("OK") { conflictError = nil }
        } message: {
            Text(conflictError ?? "")
        }
        .alert("Delete Shortcut?", isPresented: .init(
            get: { shortcutToDelete != nil },
            set: { if !$0 { shortcutToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) { shortcutToDelete = nil }
            Button("Delete", role: .destructive) {
                if let shortcut = shortcutToDelete {
                    withAnimation { appState.shortcutStore.deleteShortcut(id: shortcut.id) }
                }
                shortcutToDelete = nil
            }
        } message: {
            if let shortcut = shortcutToDelete {
                Text("Remove '\(shortcut.keyCombo.displayString)'?")
            }
        }
    }
    
    // MARK: - Sidebar
    
    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Spacing for traffic lights
            Color.clear.frame(height: 48)
            
            // Navigation Items
            VStack(spacing: 2) {
                ForEach(NavigationItem.allCases, id: \.self) { item in
                    Button {
                        selectedItem = item
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: item.icon)
                                .font(.system(size: 15)) // Slightly larger
                                .frame(width: 24)
                            
                            Text(item.rawValue)
                                .font(.system(size: 13, weight: .medium))
                            
                            Spacer()
                        }
                        .foregroundStyle(selectedItem == item ? textPrimary : textSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(selectedItem == item ? (colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05)) : .clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                }
            }
            .padding(.horizontal, 10)
            
            Spacer()
        }
    }
    
    // MARK: - Main Content Areas
    
    @ViewBuilder
    private var mainContent: some View {
        switch selectedItem {
        case .shortcuts:
            shortcutsView
        case .wiki:
            WikiContentView(
                bgPrimary: bgPrimary,
                bgSecondary: bgSecondary,
                bgTertiary: bgTertiary,
                accentColor: accentColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary
            )
        case .settings:
            SettingsView()
        }
    }
    
    // MARK: - Shortcuts View
    
    private var shortcutsView: some View {
        ShortcutsExplorerView(
            onAdd: {
                editingShortcut = nil
                startRecording()
            },
            onEdit: { shortcut in
                editingShortcut = shortcut
                recordedKeyCombo = shortcut.keyCombo
                showingAssignment = true
            },
            onDelete: { shortcut in
                shortcutToDelete = shortcut
            }
        )
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "command")
                .font(.system(size: 48))
                .foregroundStyle(Color(hex: 0x222222))
            Text("No shortcuts configured")
                .font(.callout)
                .foregroundStyle(textSecondary)
            Spacer()
        }
    }
    
    // MARK: - Assignment Overlay
    
    private func assignmentOverlay(keyCombo: KeyCombo) -> some View {
        AssignmentPromptView(
            keyCombo: keyCombo,
            editingShortcut: editingShortcut,
            onSave: { action, tags in
                handleSave(keyCombo: keyCombo, action: action, tags: tags)
            },
            onCancel: {
                showingAssignment = false
                recordedKeyCombo = nil
                editingShortcut = nil
            }
        )
        .transition(.opacity)
    }
    
    private func handleSave(keyCombo: KeyCombo, action: Action, tags: [String]) {
        if let conflict = appState.shortcutStore.findConflict(for: keyCombo, excludingId: editingShortcut?.id) {
            conflictError = "'\(keyCombo.displayString)' is used by '\(conflict.action.displayName)'"
            return
        }
        
        if let editing = editingShortcut {
            var updated = editing
            updated.keyCombo = keyCombo
            updated.action = action
            updated.tags = tags
            try? appState.shortcutStore.updateShortcut(updated)
        } else {
            let newShortcut = Shortcut(keyCombo: keyCombo, action: action, tags: tags)
            try? appState.shortcutStore.addShortcut(newShortcut)
        }
        showingAssignment = false
        recordedKeyCombo = nil
        editingShortcut = nil
    }
    
    // MARK: - Recording Overlay
    
    private var recordingOverlay: some View {
        ZStack {
            bgPrimary.opacity(0.9)
            
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.1))
                        .frame(width: 80, height: 80)
                    Image(systemName: "record.circle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.red)
                        .symbolEffect(.pulse.byLayer, options: .repeating)
                }
                
                VStack(spacing: 8) {
                    Text("Recording...")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(textPrimary)
                    Text("Press any key combination")
                        .font(.subheadline)
                        .foregroundStyle(textSecondary)
                }
                
                Button("Cancel") { stopRecording() }
                    .buttonStyle(.plain)
                    .foregroundStyle(textSecondary)
                    .padding(.top, 10)
            }
        }
        .onAppear { startKeyCapture() }
        .onDisappear { stopKeyCapture() }
    }
    
    // MARK: - Permissions
    
    private var permissionsNeeded: some View {
        PermissionsNeededView(
            bgSecondary: bgSecondary,
            textSecondary: textSecondary,
            textPrimary: textPrimary,
            accentColor: accentColor,
            colorScheme: colorScheme,
            onRequestPermission: {
                appState.permissionManager.requestAccessibility()
            }
        )
    }
    
    // MARK: - Helpers
    
    private func startRecording() {
        isRecording = true
        recordedKeyCombo = nil
    }
    
    private func stopRecording() {
        isRecording = false
        recordedKeyCombo = nil
        editingShortcut = nil
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
    
    private func startKeyCapture() {
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard self.isRecording else { return event }
            
            let modifiers = KeyModifiers.from(cgEventFlags: CGEventFlags(rawValue: UInt64(event.modifierFlags.rawValue)))
            guard !modifiers.isEmpty else { return event }
            
            let keyString = KeyboardMonitor.keyString(for: event.keyCode)
            let systemKeys = ["V", "C", "X", "Z", "A", "S", "Q", "W", "Tab"]
            if modifiers == .command && systemKeys.contains(keyString.uppercased()) {
                return event
            }
            
            let keyCombo = KeyCombo(keyCode: event.keyCode, keyString: keyString, modifiers: modifiers)
            
            if self.editingShortcut == nil,
               let conflict = self.appState.shortcutStore.findConflict(for: keyCombo, excludingId: nil) {
                self.conflictError = "'\(keyCombo.displayString)' used by '\(conflict.action.displayName)'"
                self.isRecording = false
                return nil
            }
            
            self.recordedKeyCombo = keyCombo
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.isRecording = false
                self.showingAssignment = true
            }
            return nil
        }
    }
    
    private func stopKeyCapture() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
}

// MARK: - Color Hex Init
extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: alpha
        )
    }
}

// MARK: - Permissions Needed View

struct PermissionsNeededView: View {
    let bgSecondary: Color
    let textSecondary: Color
    let textPrimary: Color
    let accentColor: Color
    let colorScheme: ColorScheme
    let onRequestPermission: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            sidebarView
            contentView
        }
    }
    
    private var sidebarView: some View {
        VStack(spacing: 0) {
            searchBar
            sidebarList
        }
        .frame(width: 220)
        .background(bgSecondary.opacity(0.5))
        .overlay(
            Rectangle()
                .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                .frame(width: 1),
            alignment: .trailing
        )
    }
    
    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundStyle(textSecondary)
            Text("Search")
                .font(.system(size: 13))
                .foregroundStyle(textSecondary)
            Spacer()
        }
        .padding(8)
        .background(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.1), lineWidth: 1)
        )
        .padding(12)
    }
    
    private var sidebarList: some View {
        ScrollView {
            LazyVStack(spacing: 4) {
                allShortcutsItem
                Divider().padding(.vertical, 8)
                tagsLabel
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
    }
    
    private var allShortcutsItem: some View {
        HStack(spacing: 12) {
            Image(systemName: "rectangle.grid.2x2.fill")
                .font(.system(size: 14))
                .frame(width: 20)
                .foregroundStyle(.white)
            Text("All Shortcuts")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)
            Spacer()
            Text("0")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(accentColor)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var tagsLabel: some View {
        Text("TAGS")
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var contentView: some View {
        VStack(spacing: 0) {
            headerView
            permissionsMessage
        }
    }
    
    private var headerView: some View {
        HStack {
            Text("All Shortcuts")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(textPrimary)
            Spacer()
            Image(systemName: "plus")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(textSecondary)
                .padding(8)
                .background(colorScheme == .dark ? Color.white.opacity(0.05) : Color.white.opacity(0.5))
                .clipShape(Circle())
        }
        .padding(.horizontal, 40)
        .padding(.top, 40)
        .padding(.bottom, 24)
    }
    
    private var permissionsMessage: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 48))
                .foregroundStyle(accentColor)
            messageText
            permissionButton
            Spacer()
        }
    }
    
    private var messageText: some View {
        VStack(spacing: 8) {
            Text("Permissions Required")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(textPrimary)
            Text("Keysly needs Accessibility access to detect shortcuts.")
                .font(.subheadline)
                .foregroundStyle(textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    private var permissionButton: some View {
        Button("Open System Settings") {
            onRequestPermission()
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(accentColor)
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
