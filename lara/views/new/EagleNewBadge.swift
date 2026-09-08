import SwiftUI

struct EagleNewBadge: View {
    @Environment(\.colorScheme) private var colorScheme
    var text = LaraL10n.text(en: "NEW", es: "NUEVO")

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .heavy))
            .textCase(.uppercase)
            .tracking(0.6)
            .foregroundStyle(colorScheme == .dark ? Color.black : Color.white)
            .padding(.horizontal, 8)
            .frame(minHeight: 20)
            .background(colorScheme == .dark ? Color.white : Color.black, in: Capsule())
            .fixedSize()
    }
}
