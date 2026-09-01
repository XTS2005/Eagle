import SwiftUI
import SafariServices

private enum EagleAppSection {
    case access
    case customize
}

struct EagleAppShellView: View {
    @ObservedObject private var sceneManager = EagleSceneManager.shared
    @State private var selectedSection = EagleAppSection.customize

    var body: some View {
        ZStack {
            EagleBeta10AccessView()
                .opacity(selectedSection == .access ? 1 : 0)
                .allowsHitTesting(selectedSection == .access)

            LaraHomeView()
                .opacity(selectedSection == .customize ? 1 : 0)
                .allowsHitTesting(selectedSection == .customize)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomBar
        }
        .alert(item: $sceneManager.notice) { notice in
            Alert(
                title: Text("Eagle Scenes"),
                message: Text(notice.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .overlay {
            if sceneManager.isApplying {
                EagleBlockingProgress(
                    title: LaraL10n.text(
                        en: "Applying Scene safely",
                        es: "Aplicando Scene de forma segura"
                    ),
                    progress: sceneManager.progress
                )
            }
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 0) {
            bottomBarButton(
                section: .access,
                title: LaraL10n.text(en: "Access", es: "Acceso"),
                systemImage: "lock.shield.fill"
            )
            bottomBarButton(
                section: .customize,
                title: LaraL10n.text(en: "Customize", es: "Personalizar"),
                systemImage: "sparkles"
            )
        }
        .frame(height: 66)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Divider().opacity(0.35)
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private func bottomBarButton(
        section: EagleAppSection,
        title: String,
        systemImage: String
    ) -> some View {
        let selected = selectedSection == section
        return Button {
            selectedSection = section
        } label: {
            VStack(spacing: 4) {
                Group {
                    if selected {
                        Image(systemName: systemImage)
                            .foregroundStyle(EagleVisualTheme.accent)
                    } else {
                        Image(systemName: systemImage)
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.system(size: 25, weight: .semibold))
                .frame(height: 30)

                Text(title)
                    .font(.caption)
                    .foregroundStyle(selected ? Color.primary : Color.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

private struct TelegramSafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let controller = SFSafariViewController(url: url)
        controller.preferredControlTintColor = UIColor(red: 0.15, green: 0.62, blue: 0.87, alpha: 1)
        return controller
    }

    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}

private struct EagleBeta10AccessView: View {
    @ObservedObject private var mgr = laramgr.shared
    @ObservedObject private var sceneManager = EagleSceneManager.shared
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage(LaraLanguage.storageKey) private var language = LaraLanguage.english
    @State private var showingSettings = false
    @State private var showingTelegram = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    accessHeader

                    if sceneManager.hasPendingShortcut {
                        VStack(alignment: .leading, spacing: 10) {
                            Label(
                                LaraL10n.text(en: "Scene waiting", es: "Scene en espera"),
                                systemImage: "bolt.shield.fill"
                            )
                            .font(.headline)
                            .foregroundStyle(.primary)

                            LaraAccessView(compact: true) {
                                sceneManager.applyPendingShortcutIfNeeded()
                            }
                        }
                    } else {
                        LaraAccessView(compact: false) {
                            sceneManager.applyPendingShortcutIfNeeded()
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text(LaraL10n.text(en: "Prepare report", es: "Reporte de Preparar"))
                            .font(.headline)
                            .padding(.horizontal, 2)
                            .accessibilityAddTraits(.isHeader)
                        EaglePrepareCrashReportCard()
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text(LaraL10n.text(en: "Access tools", es: "Herramientas de acceso"))
                            .font(.headline)
                            .padding(.horizontal, 2)
                            .accessibilityAddTraits(.isHeader)

                        VStack(spacing: 0) {
                            NavigationLink(destination: EagleCompatibilityCenterView()) {
                                accessRow(
                                    title: LaraL10n.text(en: "Compatibility", es: "Compatibilidad"),
                                    subtitle: LaraL10n.text(
                                        en: "Device support and reports",
                                        es: "Compatibilidad y reportes"
                                    ),
                                    systemImage: "checkmark.shield.fill",
                                    accent: .blue
                                )
                            }

                            Divider().padding(.leading, 65)

                            NavigationLink(destination: EagleSystemView()) {
                                accessRow(
                                    title: "Eagle System",
                                    subtitle: LaraL10n.text(
                                        en: "Guardian and recovery",
                                        es: "Guardian y recuperación"
                                    ),
                                    systemImage: "shield.lefthalf.filled",
                                    accent: .indigo
                                )
                            }
                        }
                        .buttonStyle(.plain)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .strokeBorder(EagleVisualTheme.surfaceBorder(for: colorScheme), lineWidth: 1)
                        }
                        .shadow(color: EagleVisualTheme.surfaceShadow(for: colorScheme), radius: 10, y: 4)
                    }

                    telegramCard

                    trustNote
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 36)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .environmentObject(mgr)
            }
        }
    }

    private var accessHeader: some View {
        EagleHeaderBar(language: $language) {
            showingSettings = true
        }
    }

    private var deviceModelName: String {
        let full = EagleDynamicIslandCompatibility.current.displayModel
        if let cut = full.range(of: " (") {
            return String(full[..<cut.lowerBound])
        }
        return full
    }

    private var iosVersionString: String {
        let v = ProcessInfo.processInfo.operatingSystemVersion
        return v.patchVersion == 0
            ? "\(v.majorVersion).\(v.minorVersion)"
            : "\(v.majorVersion).\(v.minorVersion).\(v.patchVersion)"
    }

    private var readinessBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(mgr.sbxready ? Color.green : Color.secondary.opacity(0.32))
                .frame(width: 8, height: 8)
            Text(mgr.sbxready
                ? "\(deviceModelName) · iOS \(iosVersionString)"
                : LaraL10n.text(en: "Not identified", es: "No identificado"))
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .padding(.horizontal, 10)
        .frame(minHeight: 34)
        .background(
            Color(uiColor: .secondarySystemGroupedBackground),
            in: Capsule()
        )
        .overlay {
            Capsule().strokeBorder(.primary.opacity(0.06), lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            mgr.sbxready
                ? LaraL10n.text(
                    en: "Identified: \(deviceModelName), iOS \(iosVersionString)",
                    es: "Identificado: \(deviceModelName), iOS \(iosVersionString)"
                )
                : LaraL10n.text(en: "Not identified", es: "No identificado")
        )
    }

    private func accessRow(
        title: String,
        subtitle: String,
        systemImage: String,
        accent: Color
    ) -> some View {
        HStack(spacing: 13) {
            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)
                .frame(width: 38, height: 38)
                .background(
                    Color.primary.opacity(0.07),
                    in: RoundedRectangle(cornerRadius: 11, style: .continuous)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
            }

            Spacer(minLength: 4)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private var telegramCard: some View {
        Button {
            showingTelegram = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.24, green: 0.70, blue: 0.90),
                                    Color(red: 0.11, green: 0.52, blue: 0.79),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 23, weight: .semibold))
                        .foregroundStyle(.white)
                        .offset(x: -1, y: 1)
                }
                .frame(width: 54, height: 54)

                Text("Text me")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)
                    .eagleRainbowSweep()

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(EagleVisualTheme.surfaceBorder(for: colorScheme), lineWidth: 1)
        }
        .shadow(color: EagleVisualTheme.surfaceShadow(for: colorScheme), radius: 10, y: 4)
        .sheet(isPresented: $showingTelegram) {
            TelegramSafariView(url: URL(string: "https://t.me/LEONARDOPHL")!)
                .ignoresSafeArea()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Text me")
        .accessibilityAddTraits(.isButton)
    }

    private var trustNote: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.shield.fill")
                .foregroundStyle(.primary)
                .font(.title3)
            VStack(alignment: .leading, spacing: 3) {
                Text(LaraL10n.text(en: "You stay in control", es: "Tú mantienes el control"))
                    .font(.subheadline.weight(.semibold))
                Text(LaraL10n.text(
                    en: "Preparation starts only when you press Prepare iPhone.",
                    es: "La preparación comienza solo cuando pulsas Preparar iPhone."
                ))
                .font(.footnote)
                .foregroundStyle(EagleVisualTheme.secondaryText(for: colorScheme))
            }
            Spacer()
        }
        .padding(.top, 4)
    }
}
