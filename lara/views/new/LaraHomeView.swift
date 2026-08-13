import SwiftUI

struct LaraHomeView: View {
    @ObservedObject private var mgr = laramgr.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header

                    VStack(spacing: 16) {
                        NavigationLink(destination: AnimatedWallpapersView()) {
                            LaraFeatureCard(
                                title: "Fondos animados",
                                subtitle: "Convierte un video en un fondo para la pantalla de bloqueo.",
                                systemImage: "photo.on.rectangle.angled",
                                accent: Color(red: 0.34, green: 0.31, blue: 0.88),
                                artwork: .wallpaper
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink(destination: CardView()) {
                            LaraFeatureCard(
                                title: "Tarjetas",
                                subtitle: "Personaliza el diseño de tus tarjetas de Wallet.",
                                systemImage: "creditcard.fill",
                                accent: Color(red: 0.08, green: 0.48, blue: 0.52),
                                artwork: .card
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    trustNote
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 36)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .toolbar(.hidden, for: .navigationBar)
        }
        .tint(.blue)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Lara")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                Spacer()
                Circle()
                    .fill(mgr.sbxready ? Color.green : Color.secondary.opacity(0.25))
                    .frame(width: 9, height: 9)
                    .accessibilityLabel(mgr.sbxready ? "Lara lista" : "Lara sin preparar")
            }

            Text("Personaliza lo que realmente ves.")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }

    private var trustNote: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.shield.fill")
                .foregroundStyle(.green)
                .font(.title3)
            VStack(alignment: .leading, spacing: 3) {
                Text("Tú mantienes el control")
                    .font(.subheadline.weight(.semibold))
                Text("Lara solicita acceso solo cuando eliges aplicar un cambio.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.top, 4)
    }
}

private struct LaraFeatureCard: View {
    enum Artwork {
        case wallpaper
        case card
    }

    let title: String
    let subtitle: String
    let systemImage: String
    let accent: Color
    let artwork: Artwork

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                accent.opacity(0.12)

                switch artwork {
                case .wallpaper:
                    wallpaperArtwork
                case .card:
                    cardArtwork
                }
            }
            .frame(height: 154)
            .clipped()

            HStack(alignment: .center, spacing: 14) {
                Image(systemName: systemImage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(accent)
                    .frame(width: 38, height: 38)
                    .background(accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 11, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(18)
        }
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.primary.opacity(0.055), lineWidth: 1)
        }
        .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var wallpaperArtwork: some View {
        HStack(spacing: -22) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(accent.opacity(0.35))
                .frame(width: 92, height: 126)
                .rotationEffect(.degrees(-8))
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(accent)
                .frame(width: 96, height: 132)
                .overlay(alignment: .top) {
                    VStack(spacing: 1) {
                        Text("9:41")
                            .font(.system(size: 26, weight: .semibold, design: .rounded))
                        Text("jueves, 13 de agosto")
                            .font(.system(size: 6, weight: .medium))
                    }
                    .foregroundStyle(.white)
                    .padding(.top, 22)
                }
                .shadow(color: accent.opacity(0.25), radius: 18, y: 10)
        }
    }

    private var cardArtwork: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(accent)
            .frame(width: 220, height: 132)
            .overlay(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 34) {
                    Image(systemName: "wave.3.right")
                        .font(.title3.weight(.medium))
                    HStack {
                        Text("•••• 4242")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        Spacer()
                        Image(systemName: "apple.logo")
                    }
                }
                .foregroundStyle(.white.opacity(0.95))
                .padding(18)
            }
            .rotationEffect(.degrees(-3))
            .shadow(color: accent.opacity(0.25), radius: 18, y: 10)
    }
}
