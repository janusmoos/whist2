import Foundation

enum HistoricalDataPack: Equatable {
    case primary
    case legacyV2
    case custom(resourceName: String)

    var resourceName: String {
        switch self {
        case .primary:
            "whist_historical_data_v3"
        case .legacyV2:
            "whist_historical_data_v2"
        case let .custom(resourceName):
            resourceName
        }
    }
}

enum HistoricalDataJSONLoaderError: LocalizedError, Equatable {
    case missingResource(String)

    var errorDescription: String? {
        switch self {
        case let .missingResource(name):
            "Kunne ikke finde \(name).json i app-bundlen."
        }
    }
}

struct HistoricalDataJSONLoader {
    var bundle: Bundle
    var resourceName: String

    init(bundle: Bundle = .main, pack: HistoricalDataPack = .primary) {
        self.bundle = bundle
        self.resourceName = pack.resourceName
    }

    init(bundle: Bundle = .main, resourceName: String) {
        self.bundle = bundle
        self.resourceName = resourceName
    }

    func load() throws -> HistoricalWhistData {
        guard let url = bundle.url(forResource: resourceName, withExtension: "json") else {
            throw HistoricalDataJSONLoaderError.missingResource(resourceName)
        }
        let data = try Data(contentsOf: url)
        return try decode(data)
    }

    func decode(_ data: Data) throws -> HistoricalWhistData {
        try JSONDecoder().decode(HistoricalWhistData.self, from: data)
    }
}
