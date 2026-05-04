import SwiftUI

extension Suit {
    /// Røde kulører (♥ ♦) og «sorte» kulører (♠ ♣), tilpasset lys/mørk tilstand.
    func playingCardForegroundColor(colorScheme: ColorScheme) -> Color {
        switch self {
        case .hearts, .diamonds:
            Color.red
        case .clubs, .spades:
            colorScheme == .dark ? Color(white: 0.95) : Color(white: 0.05)
        }
    }
}

/// Farvelægger Unicode-kulørsymboler i en streng (♠ ♣ sorte, ♥ ♦ røde); øvrige tegn uændret.
enum SuitColoredInlineText {
    static func build(_ string: String, colorScheme: ColorScheme) -> Text {
        let blackSuit = colorScheme == .dark ? Color(white: 0.95) : Color(white: 0.05)
        return string.reduce(Text("")) { partial, character in
            let piece = String(character)
            switch character {
            case "♥", "♦":
                return partial + Text(piece).foregroundStyle(Color.red)
            case "♠", "♣":
                return partial + Text(piece).foregroundStyle(blackSuit)
            default:
                return partial + Text(piece).foregroundStyle(.primary)
            }
        }
    }
}
