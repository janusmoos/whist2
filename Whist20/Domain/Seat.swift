/// De fire faste pladser om bordet (erstatter hardkodede spillere med stabile enum-værdier).
enum Seat: Int, CaseIterable, Codable, Hashable, Sendable {
    case north = 0
    case east = 1
    case south = 2
    case west = 3

    static var all: [Seat] { Array(allCases) }

    /// De tre pladser, der ikke er `seat`.
    func others() -> [Seat] {
        Seat.all.filter { $0 != self }
    }

    /// Retning om bordet (til hjælpetekst).
    var compassLabel: String {
        switch self {
        case .north: "Nord"
        case .east: "Øst"
        case .south: "Syd"
        case .west: "Vest"
        }
    }

    /// Standardnavne som i den tidligere app (fast plads → navn).
    var playerDisplayName: String {
        switch self {
        case .north: "Christian"
        case .east: "Peter"
        case .south: "Thomas"
        case .west: "Janus"
        }
    }
}
