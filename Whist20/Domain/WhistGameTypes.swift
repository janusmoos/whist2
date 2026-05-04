import Foundation

// MARK: - Normale spil

enum VipLevel: String, Codable, Hashable, CaseIterable, Sendable {
    case single = "første"
    case double = "anden"
    case triple = "tredje"

    var multiplier: Int {
        switch self {
        case .single: return 2
        case .double: return 4
        case .triple: return 8
        }
    }
}

enum NormalGameType: Hashable, Sendable {
    case almindelig
    case sans
    case halve
    case gode
    case vip(VipLevel)

    var baseMultiplier: Int {
        switch self {
        case .almindelig: return 1
        case .sans, .halve, .gode: return 2
        case .vip(let level): return level.multiplier
        }
    }
}

// MARK: - Sol

enum SolType: Hashable, Sendable, CaseIterable {
    case normal
    case pure
    case halfDealer
    case dealer

    var maxAllowedTricks: Int {
        switch self {
        case .normal: return 1
        case .pure, .halfDealer, .dealer: return 0
        }
    }

    var pointsPerOpponent: Int {
        switch self {
        case .normal: return 4
        case .pure: return 8
        case .halfDealer: return 16
        case .dealer: return 32
        }
    }
}

// MARK: - Kulør (domæne – uden SwiftUI)

enum Suit: String, CaseIterable, Codable, Hashable, Sendable {
    case spades = "Spar"
    case hearts = "Hjerter"
    case diamonds = "Ruder"
    case clubs = "Klør"

    /// Kulør-ikon til resume og UI (ikke `rawValue`-navnet).
    var cardSymbol: String {
        switch self {
        case .spades: "♠"
        case .hearts: "♥"
        case .diamonds: "♦"
        case .clubs: "♣"
        }
    }
}
