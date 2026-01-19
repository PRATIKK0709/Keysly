import SwiftUI

struct AssignmentPromptView: View {
    
    let keyCombo: KeyCombo
    let editingShortcut: Shortcut?
    let onSave: (Action, [String]) -> Void
    let onCancel: () -> Void
    
    @State private var selectedActionType: ActionType = .app
    @State private var selectedApp: AppInfo?
    @State private var urlString: String = "https://"
    @State private var scriptContent: String = ""
    @State private var scriptType: ScriptType = .shell
    @State private var selectedSystemAction: SystemActionType = .toggleDarkMode
    @State private var selectedShortcutName: String?
    @State private var typeTextContent: String = ""
    @State private var typeTextName: String = ""
    @State private var tags: [String] = []
    @State private var newTagText: String = ""
    @State private var didInitialize = false
    
    // White & Orange Theme Colors
    private let bgPrimary = Color(hex: 0xFFFFFF)
    private let bgSecondary = Color(hex: 0xF5F5F7)
    private let bgTertiary = Color(hex: 0xE5E5EB)
    private let accentColor = Color(hex: 0xFF9500)
    private let textPrimary = Color(hex: 0x000000)
    private let textSecondary = Color(hex: 0x6E6E73)
    private let textTertiary = Color(hex: 0x8E8E93)
    
    enum ActionType: String, CaseIterable {
        case app = "App"
        case url = "URL"
        case script = "Script"
        case system = "System"
        case shortcut = "Shortcut"
        case typeText = "Type Text"
        
        var icon: String {
            switch self {
            case .app: return "app.dashed"
            case .url: return "globe"
            case .script: return "terminal"
            case .system: return "gearshape"
            case .shortcut: return "bolt.fill"
            case .typeText: return "text.cursor"
            }
        }
    }
    
    var body: some View {
        ZStack {
            bgPrimary.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header (Key Combo)
                VStack(spacing: 16) {
                    HStack(spacing: 6) {
                        ForEach(keyComboKeys, id: \.self) { key in
                            Text(key)
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(accentColor)
                                .frame(minWidth: 40, minHeight: 40)
                                .background(accentColor.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(accentColor.opacity(0.2), lineWidth: 1)
                                )
                        }
                    }
                    
                    Text(editingShortcut != nil ? "Edit Action" : "Assign Action")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(textSecondary)
                }
                .padding(.top, 40)
                .padding(.bottom, 32)
                
                // Central Type Selection
                VStack(spacing: 24) {
                    HStack(spacing: 12) {
                        ForEach(ActionType.allCases, id: \.self) { type in
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedActionType = type
                                }
                            } label: {
                                VStack(spacing: 12) {
                                    Image(systemName: type.icon)
                                        .font(.system(size: 26)) // Larger icon
                                        .foregroundStyle(selectedActionType == type ? accentColor : textSecondary)
                                    
                                    Text(type.rawValue)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(selectedActionType == type ? textPrimary : textSecondary)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 90) // Taller card
                                .background(selectedActionType == type ? Color.white : bgSecondary)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(selectedActionType == type ? accentColor : Color.clear, lineWidth: 2)
                                )
                                .shadow(
                                    color: selectedActionType == type ? accentColor.opacity(0.3) : Color.black.opacity(0.05),
                                    radius: selectedActionType == type ? 8 : 2,
                                    y: selectedActionType == type ? 4 : 1
                                )
                            }
                            .buttonStyle(.plain)
                            .scaleEffect(selectedActionType == type ? 1.02 : 1.0) // Subtle scale up
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Selected Content Area
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            Text(selectedActionType.rawValue)
                                .font(.title3) // Larger title
                                .fontWeight(.bold)
                                .foregroundStyle(textPrimary)
                            
                            actionConfiguration
                        }
                        .padding(.vertical, 16)
                    }
                    .padding(.horizontal, 24)
                }
                
                // Tags Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Tags")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(textSecondary)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        // Tag Input
                        HStack {
                            Image(systemName: "tag")
                                .foregroundStyle(textSecondary)
                            TextField("Add a tag (Enter)", text: $newTagText)
                                .textFieldStyle(.plain)
                                .font(.system(size: 14))
                                .onSubmit {
                                    addTag()
                                }
                        }
                        .padding(12)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(bgTertiary, lineWidth: 1)
                        )
                        
                        // Tags Flow
                        if !tags.isEmpty {
                            FlowLayout(spacing: 8) {
                                ForEach(tags, id: \.self) { tag in
                                    HStack(spacing: 4) {
                                        Text(tag)
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundStyle(accentColor)
                                        
                                        Button {
                                            removeTag(tag)
                                        } label: {
                                            Image(systemName: "xmark")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundStyle(accentColor.opacity(0.6))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(accentColor.opacity(0.1))
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(accentColor.opacity(0.2), lineWidth: 1)
                                    )
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                
                Spacer()
                
                // Footer
                HStack {
                    Button("Cancel") {
                        onCancel()
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(textSecondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(bgSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .keyboardShortcut(.escape, modifiers: [])
                    
                    Spacer()
                    
                    Button {
                        var finalTags = tags
                        let trimmed = newTagText.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty && !finalTags.contains(trimmed) {
                            finalTags.append(trimmed)
                        }
                        
                        if let action = buildAction() {
                            onSave(action, finalTags)
                        }
                    } label: {
                        Text(editingShortcut != nil ? "Update Action" : "Save Action")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(canSave ? accentColor : accentColor.opacity(0.3))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSave)
                    .keyboardShortcut(.return, modifiers: .command)
                }
                .padding(24)
                .background(bgPrimary)
                .overlay(Rectangle().fill(bgTertiary).frame(height: 1), alignment: .top)
            }
        }
        // Removed fixed frame to allow full expansion in content area
        .onAppear {
            initializeFromEditing()
        }
    }
    
    private var keyComboKeys: [String] {
        var keys: [String] = []
        if keyCombo.modifiers.contains(.control) { keys.append("⌃") }
        if keyCombo.modifiers.contains(.option) { keys.append("⌥") }
        if keyCombo.modifiers.contains(.shift) { keys.append("⇧") }
        if keyCombo.modifiers.contains(.command) { keys.append("⌘") }
        keys.append(keyCombo.keyString.uppercased())
        return keys
    }
    
    private func initializeFromEditing() {
        guard !didInitialize, let shortcut = editingShortcut else { return }
        didInitialize = true
        
        switch shortcut.action {
        case .launchApp(let bundleId, let name):
            selectedActionType = .app
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
                let icon = NSWorkspace.shared.icon(forFile: url.path)
                selectedApp = AppInfo(id: bundleId, name: name, icon: icon)
            }
        case .openURL(let url, _):
            selectedActionType = .url
            urlString = url.absoluteString
        case .runInlineScript(let script, let type):
            selectedActionType = .script
            scriptContent = script
            scriptType = type
        case .runScript(let path, let type):
            selectedActionType = .script
            scriptContent = "# Script at: \(path)"
            scriptType = type
        case .systemAction(let type):
            selectedActionType = .system
            selectedSystemAction = type
        case .runShortcut(let name):
            selectedActionType = .shortcut
            selectedShortcutName = name
        case .chain:
            selectedActionType = .app
        case .typeText(let text, let name):
            selectedActionType = .typeText
            typeTextContent = text
            typeTextName = name
        }
        
        // Initialize Tags
        tags = shortcut.tags
    }
    
    // MARK: - Action Configuration
    
    @ViewBuilder
    private var actionConfiguration: some View {
        switch selectedActionType {
        case .app:
            appPicker
        case .url:
            urlInput
        case .script:
            scriptInput
        case .system:
            systemActionPicker
        case .shortcut:
            shortcutPicker
        case .typeText:
            typeTextInput
        }
    }
    
    private var appPicker: some View {
        AppPickerButton(
            selectedApp: $selectedApp,
            bgSecondary: bgSecondary,
            bgTertiary: bgTertiary,
            textPrimary: textPrimary,
            textSecondary: textSecondary
        )
    }
    
    private var shortcutPicker: some View {
        ShortcutPickerButton(
            selectedShortcut: $selectedShortcutName,
            bgSecondary: bgSecondary,
            bgTertiary: bgTertiary,
            textPrimary: textPrimary,
            textSecondary: textSecondary
        )
    }
    
    private var urlInput: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Website URL")
                .font(.caption)
                .foregroundStyle(textSecondary)
            
            TextField("https://", text: $urlString)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .padding(12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(bgTertiary, lineWidth: 1)
                )
        }
    }
    
    private var scriptInput: some View {
        VStack(spacing: 12) {
            HStack(spacing: 0) {
                ForEach(ScriptType.allCases, id: \.self) { type in
                    Button {
                        scriptType = type
                    } label: {
                        Text(type.rawValue)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(scriptType == type ? textPrimary : textSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(scriptType == type ? Color.white : bgSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .shadow(color: scriptType == type ? Color.black.opacity(0.05) : .clear, radius: 2)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(4)
            .background(bgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            TextEditor(text: $scriptContent)
                .font(.system(size: 12, design: .monospaced))
                .scrollContentBackground(.hidden)
                .padding(12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(bgTertiary, lineWidth: 1)
                )
                .frame(minHeight: 120)
        }
    }
    
    private var typeTextInput: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Snippet Name
            VStack(alignment: .leading, spacing: 8) {
                Text("Snippet Name")
                    .font(.caption)
                    .foregroundStyle(textSecondary)
                
                TextField("e.g. Email Signature, Address, etc.", text: $typeTextName)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .padding(12)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(bgTertiary, lineWidth: 1)
                    )
            }
            
            // Text Content
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Text to Type")
                        .font(.caption)
                        .foregroundStyle(textSecondary)
                    
                    Spacer()
                    
                    Text("\(typeTextContent.count) characters")
                        .font(.caption2)
                        .foregroundStyle(textTertiary)
                }
                
                TextEditor(text: $typeTextContent)
                    .font(.system(size: 13))
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(bgTertiary, lineWidth: 1)
                    )
                    .frame(minHeight: 100)
                
                // Hint
                HStack(spacing: 4) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(accentColor.opacity(0.7))
                    
                    Text("Use \\n for new lines. Special characters and emoji are supported.")
                        .font(.caption2)
                        .foregroundStyle(textTertiary)
                }
            }
        }
    }
    private var systemActionPicker: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 12)], spacing: 12) {
            ForEach(SystemActionType.allCases, id: \.self) { type in
                Button {
                    selectedSystemAction = type
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: type.iconName)
                            .font(.system(size: 20))
                            .foregroundStyle(selectedSystemAction == type ? accentColor : textSecondary)
                        
                        Text(type.rawValue)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(selectedSystemAction == type ? textPrimary : textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .background(selectedSystemAction == type ? Color.white : Color.white.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedSystemAction == type ? accentColor : bgTertiary, lineWidth: selectedSystemAction == type ? 2 : 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Logic
    
    private var canSave: Bool {
        switch selectedActionType {
        case .app: return selectedApp != nil
        case .url: return URL(string: urlString) != nil && urlString.count > 8
        case .script: return !scriptContent.isEmpty
        case .system: return true
        case .shortcut: return selectedShortcutName != nil
        case .typeText: return !typeTextContent.isEmpty
        }
    }
    
    private func buildAction() -> Action? {
        switch selectedActionType {
        case .app:
            guard let app = selectedApp else { return nil }
            return .launchApp(bundleId: app.bundleId, appName: app.name)
        case .url:
            guard let url = URL(string: urlString) else { return nil }
            return .openURL(url: url, name: nil)
        case .script:
            return .runInlineScript(script: scriptContent, type: scriptType)
        case .system:
            return .systemAction(selectedSystemAction)
        case .shortcut:
            guard let shortcut = selectedShortcutName else { return nil }
            return .runShortcut(name: shortcut)
        case .typeText:
            return .typeText(text: typeTextContent, name: typeTextName)
        }
    }
    
    private func addTag() {
        let trimmed = newTagText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !tags.contains(trimmed) else { return }
        withAnimation {
            tags.append(trimmed)
            newTagText = ""
        }
    }
    
    private func removeTag(_ tag: String) {
        withAnimation {
            tags.removeAll { $0 == tag }
        }
    }
}

// MARK: - Flow Layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let height = rows.last?.maxY ?? 0
        return CGSize(width: proposal.width ?? 0, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        for row in rows {
            for element in row.elements {
                element.subview.place(at: CGPoint(x: bounds.minX + element.x, y: bounds.minY + element.y), proposal: .unspecified)
            }
        }
    }
    
    struct Row {
        var elements: [Element] = []
        var y: CGFloat = 0
        var height: CGFloat = 0
        
        var maxY: CGFloat { y + height }
    }
    
    struct Element {
        let subview: LayoutSubview
        let x: CGFloat
        let y: CGFloat
    }
    
    func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var currentRow = Row()
        var x: CGFloat = 0
        var y: CGFloat = 0
        let maxWidth = proposal.width ?? 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if x + size.width > maxWidth && !currentRow.elements.isEmpty {
                // New row
                y += currentRow.height + spacing
                rows.append(currentRow)
                currentRow = Row()
                x = 0
                currentRow.y = y
            }
            
            currentRow.elements.append(Element(subview: subview, x: x, y: y))
            currentRow.height = max(currentRow.height, size.height)
            x += size.width + spacing
        }
        
        if !currentRow.elements.isEmpty {
            rows.append(currentRow)
        }
        
        return rows
    }
}

// MARK: - Shortcut Selection Grid

struct ShortcutPickerButton: View {
    @Binding var selectedShortcut: String?
    let bgSecondary: Color
    let bgTertiary: Color
    let textPrimary: Color
    let textSecondary: Color
    
    @State private var shortcuts: [String] = []
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    let columns = [GridItem(.adaptive(minimum: 150), spacing: 12)]
    
    var body: some View {
        VStack(spacing: 16) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(textSecondary)
                TextField("Search shortcuts...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
            }
            .padding(12)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(bgTertiary, lineWidth: 1)
            )
            
            if isLoading {
                ProgressView()
                    .padding()
            } else if let error = errorMessage {
                Text(error)
                    .foregroundStyle(.red)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(filteredShortcuts, id: \.self) { shortcut in
                            Button {
                                selectedShortcut = shortcut
                            } label: {
                                VStack(alignment: .leading, spacing: 12) {
                                    Image(systemName: "bolt.fill")
                                        .font(.system(size: 16))
                                        .foregroundStyle(selectedShortcut == shortcut ? .white : .purple)
                                        .padding(8)
                                        .background(selectedShortcut == shortcut ? .white.opacity(0.2) : .purple.opacity(0.1))
                                        .clipShape(Circle())
                                    
                                    Text(shortcut)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(selectedShortcut == shortcut ? .white : textPrimary)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                    
                                    Spacer(minLength: 0)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .frame(height: 100)
                                .padding(12)
                                .background(selectedShortcut == shortcut ? Color(hex: 0xFF9500) : Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedShortcut == shortcut ? Color.clear : bgTertiary, lineWidth: 1)
                                )
                                .shadow(color: Color.black.opacity(0.05), radius: 2, y: 1)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(4)
                }
                .frame(maxHeight: 300) // Limit height
            }
        }
        .onAppear {
            loadShortcuts()
        }
    }
    
    private var filteredShortcuts: [String] {
        if searchText.isEmpty { return shortcuts }
        return shortcuts.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }
    
    private func loadShortcuts() {
        guard shortcuts.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let fetchedShortcuts = try await ShortcutsService.shared.listShortcuts()
                await MainActor.run {
                    self.shortcuts = fetchedShortcuts
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}


// MARK: - App Info

struct AppInfo: Identifiable, Hashable {
    let id: String
    var bundleId: String { id }
    let name: String
    let icon: NSImage?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: AppInfo, rhs: AppInfo) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - App Picker Button

struct AppPickerButton: View {
    @Binding var selectedApp: AppInfo?
    let bgSecondary: Color
    let bgTertiary: Color
    let textPrimary: Color
    let textSecondary: Color
    
    @State private var showingPicker = false
    @State private var apps: [AppInfo] = []
    @State private var searchText = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Application")
                .font(.caption)
                .foregroundStyle(textSecondary)
            
            Button {
                loadApps()
                showingPicker = true
            } label: {
                HStack {
                    if let app = selectedApp {
                        if let icon = app.icon {
                            Image(nsImage: icon)
                                .resizable()
                                .frame(width: 20, height: 20)
                        }
                        Text(app.name)
                            .foregroundStyle(textPrimary)
                    } else {
                        Text("Select an app...")
                            .foregroundStyle(textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(textSecondary)
                }
                .padding(12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(bgTertiary, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showingPicker) {
                VStack(spacing: 0) {
                    TextField("Search apps...", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .padding(12)
                    
                    Divider()
                    
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(filteredApps) { app in
                                Button {
                                    selectedApp = app
                                    showingPicker = false
                                } label: {
                                    HStack(spacing: 10) {
                                        if let icon = app.icon {
                                            Image(nsImage: icon)
                                                .resizable()
                                                .frame(width: 20, height: 20)
                                        }
                                        Text(app.name)
                                            .font(.callout)
                                            .lineLimit(1)
                                            .foregroundStyle(.primary)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .frame(height: 240)
                }
                .frame(width: 280)
            }
        }
    }
    
    private var filteredApps: [AppInfo] {
        if searchText.isEmpty { return apps }
        return apps.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    private func loadApps() {
        guard apps.isEmpty else { return }
        
        var loaded: [AppInfo] = []
        let paths = ["/Applications", "/System/Applications", NSHomeDirectory() + "/Applications"]
        
        for path in paths {
            let url = URL(fileURLWithPath: path)
            guard let contents = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil) else { continue }
            
            for appURL in contents where appURL.pathExtension == "app" {
                if let bundle = Bundle(url: appURL), let bundleId = bundle.bundleIdentifier {
                    let name = FileManager.default.displayName(atPath: appURL.path)
                    let icon = NSWorkspace.shared.icon(forFile: appURL.path)
                    loaded.append(AppInfo(id: bundleId, name: name, icon: icon))
                }
            }
        }
        
        apps = loaded.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
