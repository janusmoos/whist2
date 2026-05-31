import SwiftUI

enum SuitColorContext {
    case poster
    case picker
    case inlineText
}

extension Suit {
    var illustrationColor: Color {
        color(context: .poster, colorScheme: .light)
    }

    init?(cardSymbol: String) {
        switch cardSymbol {
        case "♠": self = .spades
        case "♥": self = .hearts
        case "♦": self = .diamonds
        case "♣": self = .clubs
        default: return nil
        }
    }

    func color(context: SuitColorContext, colorScheme: ColorScheme) -> Color {
        switch self {
        case .hearts, .diamonds:
            return ActiveGamePosterStyle.negativeScoreColor
        case .clubs, .spades:
            return ActiveGamePosterStyle.darkInkColor
        }
    }

    /// Røde kulører (♥ ♦) og «sorte» kulører (♠ ♣), tilpasset lys/mørk tilstand.
    func playingCardForegroundColor(colorScheme: ColorScheme) -> Color {
        color(context: .picker, colorScheme: colorScheme)
    }
}

/// Farvelægger Unicode-kulørsymboler i en streng (♠ ♣ sorte, ♥ ♦ røde); øvrige tegn uændret.
enum SuitColoredInlineText {
    static func build(_ string: String, colorScheme: ColorScheme, suitFontSize: CGFloat? = nil) -> Text {
        return string.reduce(Text("")) { partial, character in
            let piece = String(character)
            switch character {
            case "♥":
                return partial + suitText(piece, color: Suit.hearts.color(context: .inlineText, colorScheme: colorScheme), suitFontSize: suitFontSize)
            case "♦":
                return partial + suitText(piece, color: Suit.diamonds.color(context: .inlineText, colorScheme: colorScheme), suitFontSize: suitFontSize)
            case "♠":
                return partial + suitText(piece, color: Suit.spades.color(context: .inlineText, colorScheme: colorScheme), suitFontSize: suitFontSize)
            case "♣":
                return partial + suitText(piece, color: Suit.clubs.color(context: .inlineText, colorScheme: colorScheme), suitFontSize: suitFontSize)
            default:
                return partial + Text(piece).foregroundStyle(.primary)
            }
        }
    }

    private static func suitText(_ text: String, color: Color, suitFontSize: CGFloat?) -> Text {
        var output = Text(text).foregroundStyle(color)
        if let suitFontSize {
            output = output.font(.system(size: suitFontSize, weight: .semibold))
        }
        return output
    }
}
