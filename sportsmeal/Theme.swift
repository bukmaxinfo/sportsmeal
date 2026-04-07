import SwiftUI

enum AppTheme {
    // MARK: - Core palette
    static let background = Color(red: 0.07, green: 0.07, blue: 0.09)        // Near-black
    static let surface = Color(red: 0.11, green: 0.11, blue: 0.14)           // Card background
    static let surfaceLight = Color(red: 0.15, green: 0.15, blue: 0.19)      // Elevated surface
    static let border = Color.white.opacity(0.08)                             // Subtle glass edges

    // MARK: - Accent colors
    static let gold = Color(red: 0.85, green: 0.72, blue: 0.45)              // Primary accent — champagne gold
    static let goldLight = Color(red: 0.92, green: 0.82, blue: 0.58)         // Highlight gold
    static let goldSubtle = Color(red: 0.85, green: 0.72, blue: 0.45).opacity(0.15)

    // MARK: - Semantic colors
    static let positive = Color(red: 0.40, green: 0.78, blue: 0.58)          // Muted emerald
    static let negative = Color(red: 0.85, green: 0.35, blue: 0.35)          // Soft red
    static let warning = Color(red: 0.90, green: 0.70, blue: 0.30)           // Amber

    // MARK: - Text
    static let textPrimary = Color.white.opacity(0.92)
    static let textSecondary = Color.white.opacity(0.55)
    static let textTertiary = Color.white.opacity(0.30)

    // MARK: - Gradients
    static let goldGradient = LinearGradient(
        colors: [gold, goldLight],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardGradient = LinearGradient(
        colors: [surface, surface.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let glassGradient = LinearGradient(
        colors: [Color.white.opacity(0.06), Color.white.opacity(0.02)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Reusable card modifier
struct LuxuryCard: ViewModifier {
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(AppTheme.glassGradient)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppTheme.border, lineWidth: 1)
            )
    }
}

struct LuxuryButton: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(AppTheme.goldGradient)
            .foregroundStyle(.black)
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

extension View {
    func luxuryCard(padding: CGFloat = 16) -> some View {
        modifier(LuxuryCard(padding: padding))
    }

    func luxuryButton() -> some View {
        modifier(LuxuryButton())
    }
}
