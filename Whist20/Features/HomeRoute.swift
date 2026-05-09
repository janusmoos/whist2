import Foundation

/// Navigation fra forsiden (`HomeView`).
enum HomeRoute: Hashable {
    case senesteSpil
    /// Kladde / aktiv melding for den valgte spilledag (samme data som under «Tilføj spil» på enheden).
    case activeGame(gameDayId: UUID)
    case gameDay(UUID, openAddHand: Bool)
    case hand(gameDayId: UUID, handId: UUID)
    case newGameDay
    case standings
    case settings
    case scorecard
    case allGameDays
}
