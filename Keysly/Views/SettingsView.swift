import SwiftUI

struct SettingsView: View {
    
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
    
    // Persistent Settings
    @AppStorage("compactView") private var gridViewEnabled = false
    @AppStorage("selectedTheme") private var selectedTheme = "system"
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    
    // Theme Colors (Adaptive)
    private var textPrimary: Color {
        colorScheme == .dark ? .white : .black
    }
    private var textSecondary: Color {
        colorScheme == .dark ? Color(hex: 0x8E8E93) : Color(hex: 0x6E6E73)
    }
    private var accentColor: Color {
        Color(hex: 0xFF9500)
    }
    private var bgPrimary: Color {
        colorScheme == .dark ? Color(hex: 0x1C1C1E) : .white
    }
    private var bgSecondary: Color {
        colorScheme == .dark ? Color(hex: 0x2C2C2E) : Color(hex: 0xF5F5F7)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                
                // MARK: - App Header
                appHeader
                
                // MARK: - Appearance Section
                sectionContainer(title: "Appearance") {
                    VStack(spacing: 16) {
                        // Theme Picker
                        HStack {
                            Label("Theme", systemImage: "paintpalette.fill")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(textPrimary)
                            
                            Spacer()
                            
                            themePicker
                        }
                        
                        Divider()
                        
                        // Grid View Toggle
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Label("Grid View", systemImage: "square.grid.2x2.fill")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(textPrimary)
                                
                                Text("Display shortcuts as cards")
                                    .font(.system(size: 11))
                                    .foregroundStyle(textSecondary)
                                    .padding(.leading, 24)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: $gridViewEnabled)
                                .toggleStyle(SwitchToggleStyle(tint: accentColor))
                                .labelsHidden()
                        }
                    }
                }
                
                // MARK: - System Section
                sectionContainer(title: "System") {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Label("Accessibility", systemImage: "hand.raised.fill")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(textPrimary)
                            
                            Text(appState.permissionManager.isFullyReady ? "Permission granted" : "Required for monitoring")
                                .font(.system(size: 11))
                                .foregroundStyle(appState.permissionManager.isFullyReady ? textSecondary : Color.red.opacity(0.8))
                                .padding(.leading, 24)
                        }
                        
                        Spacer()
                        
                        if appState.permissionManager.isFullyReady {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(Color.green)
                        } else {
                            Button("Grant Access") {
                                appState.permissionManager.openAccessibilitySettings()
                            }
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(accentColor)
                            .clipShape(Capsule())
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                // MARK: - About Section
                sectionContainer(title: "About") {
                    VStack(alignment: .leading, spacing: 16) {
                        // Description
                        Text("A minimalistic macOS utility for managing global keyboard shortcuts.")
                            .font(.system(size: 13))
                            .foregroundStyle(textSecondary)
                            .lineSpacing(3)
                        
                        // Divider
                        Rectangle()
                            .fill(textSecondary.opacity(0.15))
                            .frame(height: 1)
                        
                        // Credits & Links
                        HStack(alignment: .top, spacing: 32) {
                            // Project Info
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Open Source")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(textSecondary.opacity(0.6))
                                    .textCase(.uppercase)
                                
                                Text("Mistilteinn")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(textPrimary)
                            }
                            
                            // Links
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Links")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(textSecondary.opacity(0.6))
                                    .textCase(.uppercase)
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Link(destination: URL(string: "https://www.mistilteinn.xyz")!) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "globe")
                                                .font(.system(size: 11))
                                            Text("Website")
                                        }
                                    }
                                    
                                    Link(destination: URL(string: "https://github.com/MistilteinnDevs/Keysly")!) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "chevron.left.forwardslash.chevron.right")
                                                .font(.system(size: 11))
                                            Text("GitHub")
                                        }
                                    }
                                }
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(accentColor)
                            }
                        }
                    }
                }
                
                // Debug Section (only in DEBUG builds)
                #if DEBUG
                sectionContainer(title: "Developer") {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Label("Reset Onboarding", systemImage: "arrow.counterclockwise")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(textPrimary)
                            
                            Text("Show onboarding on next launch")
                                .font(.system(size: 11))
                                .foregroundStyle(textSecondary)
                                .padding(.leading, 24)
                        }
                        
                        Spacer()
                        
                        Button("Reset") {
                            hasCompletedOnboarding = false
                        }
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.red.opacity(0.8))
                        .clipShape(Capsule())
                        .buttonStyle(.plain)
                    }
                }
                #endif
            }
            .padding(40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(bgPrimary)
    }
    
    // MARK: - App Header
    private var appHeader: some View {
        HStack(spacing: 16) {
            Image("app-icon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: Color.black.opacity(0.1), radius: 4, y: 2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Keysly")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(textPrimary)
                
                Text("v0.1 Pre-Alpha")
                    .font(.system(size: 13))
                    .foregroundStyle(textSecondary)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Custom Theme Picker
    private var themePicker: some View {
        HStack(spacing: 0) {
            themeOption(value: "light", icon: "sun.max.fill", label: "Light")
            themeOption(value: "dark", icon: "moon.fill", label: "Dark")
            themeOption(value: "system", icon: "laptopcomputer", label: "System")
        }
        .padding(3)
        .background(bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private func themeOption(value: String, icon: String, label: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedTheme = value
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(label)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(selectedTheme == value ? .white : textPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(selectedTheme == value ? accentColor : .clear)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Section Container Helper
    @ViewBuilder
    private func sectionContainer<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(textSecondary)
                .textCase(.uppercase)
            
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
