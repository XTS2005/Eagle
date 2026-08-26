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
                            .foregroundStyle(EagleSpectrumStyle.gradient)
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

struct EagleSmileyFlower: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var size: CGFloat = 40
    var revolutionSeconds: Double = 22

    private let petalColors: [Color] = [
        Color(red: 0.95, green: 0.25, blue: 0.62),
        Color(red: 0.93, green: 0.22, blue: 0.26),
        Color(red: 0.98, green: 0.56, blue: 0.15),
        Color(red: 0.99, green: 0.78, blue: 0.16),
        Color(red: 0.55, green: 0.80, blue: 0.22),
        Color(red: 0.18, green: 0.76, blue: 0.55),
        Color(red: 0.20, green: 0.68, blue: 0.92),
        Color(red: 0.28, green: 0.46, blue: 0.92),
        Color(red: 0.55, green: 0.35, blue: 0.86),
        Color(red: 0.76, green: 0.30, blue: 0.82),
    ]

    private let outline = Color(red: 0.09, green: 0.08, blue: 0.11)

    var body: some View {
        ZStack {
            petalRing
            face
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private var petalRing: some View {
        let count = petalColors.count
        let petalW = size * 0.30
        let petalH = size * 0.42
        let radius = size * 0.28
        return TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { context in
            let seconds = context.date.timeIntervalSinceReferenceDate
            let angle = reduceMotion
                ? 0
                : (seconds.truncatingRemainder(dividingBy: revolutionSeconds) / revolutionSeconds) * 360.0
            ZStack {
                ForEach(0..<count, id: \.self) { index in
                    Capsule(style: .continuous)
                        .fill(petalColors[index])
                        .overlay {
                            Capsule(style: .continuous)
                                .strokeBorder(outline, lineWidth: max(1, size * 0.028))
                        }
                        .frame(width: petalW, height: petalH)
                        .offset(y: -radius)
                        .rotationEffect(.degrees(Double(index) / Double(count) * 360.0))
                }
            }
            .rotationEffect(.degrees(angle))
        }
        .frame(width: size, height: size)
    }

    private var face: some View {
        let faceD = size * 0.54
        return ZStack {
            Circle()
                .fill(Color(red: 0.99, green: 0.82, blue: 0.10))
                .overlay { Circle().strokeBorder(outline, lineWidth: max(1, size * 0.032)) }
                .frame(width: faceD, height: faceD)

            HStack(spacing: faceD * 0.48) {
                cheek(faceD)
                cheek(faceD)
            }
            .offset(y: faceD * 0.13)

            HStack(spacing: faceD * 0.26) {
                eye(faceD)
                eye(faceD)
            }
            .offset(y: -faceD * 0.08)

            mouth(faceD)
                .offset(y: faceD * 0.19)
        }
    }

    private func eye(_ faceD: CGFloat) -> some View {
        Capsule()
            .fill(outline)
            .frame(width: faceD * 0.12, height: faceD * 0.22)
            .overlay(alignment: .topLeading) {
                Circle()
                    .fill(.white)
                    .frame(width: faceD * 0.05, height: faceD * 0.05)
                    .offset(x: faceD * 0.02, y: faceD * 0.02)
            }
    }

    private func cheek(_ faceD: CGFloat) -> some View {
        Circle()
            .fill(Color(red: 0.98, green: 0.55, blue: 0.25).opacity(0.5))
            .frame(width: faceD * 0.13, height: faceD * 0.13)
    }

    private func mouth(_ faceD: CGFloat) -> some View {
        let mouthW = faceD * 0.46
        let mouthH = faceD * 0.27
        return EagleSmileMouth()
            .fill(outline)
            .frame(width: mouthW, height: mouthH)
            .overlay(alignment: .bottom) {
                Circle()
                    .fill(Color(red: 0.95, green: 0.22, blue: 0.34))
                    .frame(width: mouthW * 0.42, height: mouthW * 0.42)
                    .offset(y: mouthH * 0.16)
            }
            .clipShape(EagleSmileMouth())
    }
}

struct EagleSmileMouth: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.midX, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.maxY)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.maxY)
        )
        path.closeSubpath()
        return path
    }
}

private struct EagleBeta10AccessView: View {
    @ObservedObject private var mgr = laramgr.shared
    @ObservedObject private var sceneManager = EagleSceneManager.shared
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
                                .strokeBorder(.primary.opacity(0.05), lineWidth: 1)
                        }
                    }

                    telegramCard

                    VStack(alignment: .leading, spacing: 10) {
                        Text(LaraL10n.text(en: "Prepare report", es: "Reporte de Preparar"))
                            .font(.headline)
                            .padding(.horizontal, 2)
                            .accessibilityAddTraits(.isHeader)
                        EaglePrepareCrashReportCard()
                    }

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
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                HStack(spacing: 10) {
                    Text("Eagle")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(EagleSpectrumStyle.wordmarkGradient)
                        .minimumScaleFactor(0.82)
                        .accessibilityAddTraits(.isHeader)

                    EagleSmileyFlower(size: 40)
                }

                Spacer(minLength: 8)

                readinessBadge

                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 44, height: 44)
                        .background(
                            Color(uiColor: .secondarySystemGroupedBackground),
                            in: Circle()
                        )
                        .overlay {
                            Circle().strokeBorder(.primary.opacity(0.06), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(LaraL10n.text(en: "Settings", es: "Ajustes"))
            }

            Text(LaraL10n.text(
                en: "Prepare and verify system access.",
                es: "Prepara y verifica el acceso al sistema."
            ))
            .font(.title3)
            .foregroundStyle(.secondary)
        }
    }

    private var readinessBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(mgr.sbxready ? Color.green : Color.secondary.opacity(0.32))
                .frame(width: 8, height: 8)
            Text(mgr.sbxready
                ? LaraL10n.text(en: "Ready", es: "Lista")
                : LaraL10n.text(en: "Setup", es: "Preparar"))
                .font(.caption.weight(.semibold))
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
                .foregroundStyle(accent)
                .frame(width: 38, height: 38)
                .background(
                    accent.opacity(0.14),
                    in: RoundedRectangle(cornerRadius: 11, style: .continuous)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
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
                    .foregroundStyle(EagleSpectrumStyle.gradient)

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
                .strokeBorder(.primary.opacity(0.06), lineWidth: 1)
        }
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
                .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.top, 4)
    }
}
