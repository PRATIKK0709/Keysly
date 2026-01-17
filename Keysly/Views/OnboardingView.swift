import SwiftUI

struct OnboardingView: View {
    
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
    @Binding var isPresented: Bool
    
    @State private var currentPage = 0
    
    private let totalPages = 5
    
    // Theme Colors
    private var accentColor: Color { Color(hex: 0xFF9500) }
    private var textPrimary: Color { colorScheme == .dark ? .white : .black }
    private var textSecondary: Color { colorScheme == .dark ? Color(hex: 0x8E8E93) : Color(hex: 0x6E6E73) }
    private var bgPrimary: Color { colorScheme == .dark ? Color(hex: 0x1C1C1E) : .white }
    
    var body: some View {
        VStack(spacing: 0) {
            // Content Area (fixed height)
            Group {
                switch currentPage {
                case 0: welcomePage
                case 1: shortcutsPage
                case 2: wikiPage
                case 3: settingsPage
                case 4: permissionsPage
                default: welcomePage
                }
            }
            .frame(height: 420)
            
            Spacer(minLength: 0)
            
            // Divider
            Rectangle()
                .fill(textSecondary.opacity(0.15))
                .frame(height: 1)
            
            // Navigation Bar (fixed at bottom)
            navigationBar
        }
        .frame(width: 560, height: 500)
        .background(bgPrimary)
    }
    
    // MARK: - Navigation Bar
    
    private var navigationBar: some View {
        HStack {
            // Skip Button
            if currentPage < totalPages - 1 {
                Button("Skip") {
                    withAnimation { currentPage = totalPages - 1 }
                }
                .buttonStyle(.plain)
                .font(.system(size: 13))
                .foregroundStyle(textSecondary)
                .frame(width: 60, alignment: .leading)
            } else {
                Spacer().frame(width: 60)
            }
            
            Spacer()
            
            // Page Indicators
            HStack(spacing: 8) {
                ForEach(0..<totalPages, id: \.self) { index in
                    Circle()
                        .fill(currentPage == index ? accentColor : textSecondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .onTapGesture { withAnimation { currentPage = index } }
                }
            }
            
            Spacer()
            
            // Next/Get Started Button
            Button(currentPage == totalPages - 1 ? "Get Started" : "Next") {
                if currentPage == totalPages - 1 {
                    isPresented = false
                } else {
                    withAnimation { currentPage += 1 }
                }
            }
            .buttonStyle(.plain)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(accentColor)
            .clipShape(Capsule())
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 20)
        .background(bgPrimary)
    }
    
    // MARK: - Page 1: Welcome
    
    private var welcomePage: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // App Icon
            Image("app-icon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .shadow(color: Color.black.opacity(0.15), radius: 10, y: 5)
            
            VStack(spacing: 12) {
                Text("Welcome to Keysly")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(textPrimary)
                
                Text("A minimalistic macOS utility for managing\nglobal keyboard shortcuts.")
                    .font(.system(size: 16))
                    .foregroundStyle(textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            Spacer()
            Spacer()
        }
        .padding(40)
    }
    
    // MARK: - Page 2: Shortcuts
    
    private var shortcutsPage: some View {
        VStack(spacing: 24) {
            Spacer()
            
            featureIcon(systemName: "command.circle.fill")
            
            VStack(spacing: 12) {
                Text("Create Shortcuts")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(textPrimary)
                
                Text("Press any key combination to create a new shortcut.\nAssign it to launch apps, open URLs, run Shortcuts, or trigger system actions.")
                    .font(.system(size: 15))
                    .foregroundStyle(textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            // Feature highlights
            VStack(spacing: 12) {
                featureRow(icon: "app.fill", text: "Launch Applications")
                featureRow(icon: "globe", text: "Open URLs & Websites")
                featureRow(icon: "bolt.fill", text: "Run Apple Shortcuts")
                featureRow(icon: "gearshape.fill", text: "Trigger System Actions")
            }
            .padding(.top, 16)
            
            Spacer()
        }
        .padding(40)
    }
    
    // MARK: - Page 3: Wiki
    
    private var wikiPage: some View {
        VStack(spacing: 24) {
            Spacer()
            
            featureIcon(systemName: "book.circle.fill")
            
            VStack(spacing: 12) {
                Text("Explore the Wiki")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(textPrimary)
                
                Text("Discover keyboard shortcuts for 20+ popular macOS apps.\nLearn new shortcuts and boost your productivity.")
                    .font(.system(size: 15))
                    .foregroundStyle(textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            // App icons grid
            HStack(spacing: 16) {
                appIconPlaceholder(name: "safari", label: "Safari")
                appIconPlaceholder(name: "finder", label: "Finder")
                appIconPlaceholder(name: "mail", label: "Mail")
                appIconPlaceholder(name: "notes", label: "Notes")
                appIconPlaceholder(name: "xcode", label: "Xcode")
            }
            .padding(.top, 16)
            
            Text("+ 15 more apps")
                .font(.system(size: 13))
                .foregroundStyle(textSecondary.opacity(0.7))
            
            Spacer()
        }
        .padding(40)
    }
    
    // MARK: - Page 4: Settings
    
    private var settingsPage: some View {
        VStack(spacing: 24) {
            Spacer()
            
            featureIcon(systemName: "gearshape.circle.fill")
            
            VStack(spacing: 12) {
                Text("Customize Your Experience")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(textPrimary)
                
                Text("Make Keysly yours with customizable themes and layouts.")
                    .font(.system(size: 15))
                    .foregroundStyle(textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            // Settings highlights
            VStack(spacing: 12) {
                featureRow(icon: "sun.max.fill", text: "Light, Dark, or System Theme")
                featureRow(icon: "square.grid.2x2.fill", text: "Grid or List View")
                featureRow(icon: "tag.fill", text: "Organize with Tags")
            }
            .padding(.top, 16)
            
            Spacer()
        }
        .padding(40)
    }
    
    // MARK: - Page 5: Permissions
    
    private var permissionsPage: some View {
        VStack(spacing: 24) {
            Spacer()
            
            featureIcon(systemName: "hand.raised.circle.fill")
            
            VStack(spacing: 12) {
                Text("One Last Step")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(textPrimary)
                
                Text("Keysly needs Accessibility permission to\ncapture global keyboard shortcuts.")
                    .font(.system(size: 15))
                    .foregroundStyle(textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            // Permission status
            permissionCard
                .padding(.top, 16)
            
            Spacer()
        }
        .padding(40)
    }
    
    private var permissionCard: some View {
        HStack(spacing: 16) {
            // Status icon
            Group {
                if appState.permissionManager.isFullyReady {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.red)
                }
            }
            .font(.system(size: 28))
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Accessibility Access")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(textPrimary)
                
                Text(appState.permissionManager.isFullyReady ? "Permission granted" : "Required for shortcuts")
                    .font(.system(size: 12))
                    .foregroundStyle(textSecondary)
            }
            
            Spacer()
            
            if !appState.permissionManager.isFullyReady {
                Button("Grant Access") {
                    appState.permissionManager.openAccessibilitySettings()
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(accentColor)
                .clipShape(Capsule())
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .background(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Helper Views
    
    private func featureIcon(systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 64))
            .foregroundStyle(accentColor)
    }
    
    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(accentColor)
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(textPrimary)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .frame(maxWidth: 300)
    }
    
    private func appIconPlaceholder(name: String, label: String) -> some View {
        VStack(spacing: 6) {
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId(for: name)) {
                Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                    .resizable()
                    .frame(width: 40, height: 40)
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(accentColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "app.fill")
                            .foregroundStyle(accentColor)
                    )
            }
            
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(textSecondary)
        }
    }
    
    private func bundleId(for name: String) -> String {
        switch name {
        case "safari": return "com.apple.Safari"
        case "finder": return "com.apple.finder"
        case "mail": return "com.apple.mail"
        case "notes": return "com.apple.Notes"
        case "xcode": return "com.apple.dt.Xcode"
        default: return ""
        }
    }
}
