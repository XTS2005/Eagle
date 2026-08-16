import Foundation

nonisolated enum EagleInterfaceMode: String, CaseIterable, Identifiable {
    case simple
    case advanced

    static let storageKey = "eagle.interfaceMode"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .simple:
            return LaraL10n.text(en: "Simple", es: "Simple")
        case .advanced:
            return LaraL10n.text(en: "Advanced", es: "Avanzado")
        }
    }

    var summary: String {
        switch self {
        case .simple:
            return LaraL10n.text(
                en: "Prepare, Styles, Wallpapers, and Aura Studio",
                es: "Preparar, Estilos, Fondos y Aura Studio"
            )
        case .advanced:
            return LaraL10n.text(
                en: "More tools, controlled by your feature channel",
                es: "Más herramientas, controladas por tu canal de funciones"
            )
        }
    }
}
