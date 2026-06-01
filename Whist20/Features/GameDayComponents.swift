import SwiftUI

// MARK: - Field panel

struct GameDayFieldPanel<Content: View>: View {
    var title: String
    var contentPadding: CGFloat = 12
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.custom(ActiveGamePosterStyle.resumeFontName, size: 15))
                .fontWidth(.compressed)
                .fontWeight(.semibold)
                .foregroundStyle(ActiveGamePosterStyle.darkInkColor.opacity(0.72))
                .textCase(.uppercase)
                .padding(.horizontal, max(contentPadding, 14))
                .padding(.top, 9)

            content
                .padding(.horizontal, contentPadding)
                .padding(.bottom, contentPadding == 0 ? 0 : 10)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: ActiveGamePosterStyle.cornerRadius, style: .continuous)
                .fill(ActiveGamePosterStyle.panelColor)
                .overlay {
                    RoundedRectangle(cornerRadius: ActiveGamePosterStyle.cornerRadius, style: .continuous)
                        .strokeBorder(ActiveGamePosterStyle.highlightBorderColor.opacity(0.62), lineWidth: 1)
                }
        }
        .overlay {
            RoundedRectangle(cornerRadius: ActiveGamePosterStyle.cornerRadius, style: .continuous)
                .strokeBorder(ActiveGamePosterStyle.borderColor, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: ActiveGamePosterStyle.cornerRadius, style: .continuous))
    }
}

// MARK: - Primary button

struct GameDayPrimaryButtonLabel: View {
    var title: String
    var systemImage: String
    var tint: Color = ActiveGamePosterStyle.selectedGreenColor

    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.headline.weight(.semibold))
            .foregroundStyle(ActiveGamePosterStyle.contrastTextOnColor.opacity(isEnabled ? 1 : 0.54))
            .frame(maxWidth: .infinity, minHeight: 56)
            .background {
                RoundedRectangle(cornerRadius: ActiveGamePosterStyle.cornerRadius, style: .continuous)
                    .fill(
                        isEnabled
                            ? tint
                            : ActiveGamePosterStyle.neutralMeterColor.opacity(0.36)
                    )
            }
    }
}

// MARK: - Secondary button

struct GameDaySecondaryButtonLabel: View {
    var title: String

    var body: some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(ActiveGamePosterStyle.selectedGreenColor)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background {
                RoundedRectangle(cornerRadius: ActiveGamePosterStyle.cornerRadius, style: .continuous)
                    .fill(ActiveGamePosterStyle.panelColor)
            }
            .overlay {
                RoundedRectangle(cornerRadius: ActiveGamePosterStyle.cornerRadius, style: .continuous)
                    .strokeBorder(ActiveGamePosterStyle.borderColor, lineWidth: 1)
            }
    }
}
