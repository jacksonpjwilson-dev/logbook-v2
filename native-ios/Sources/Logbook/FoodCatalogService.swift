import Foundation

enum FoodCatalogError: LocalizedError {
    case invalidResponse
    case unavailable

    var errorDescription: String? {
        switch self {
        case .invalidResponse: "The food provider returned data Logbook could not read."
        case .unavailable: "Food search is unavailable. Try again when you have a connection, or use Manual Entry."
        }
    }
}

/// Public, no-key catalogue clients. Imported records retain the provider and
/// source URL; only gram-based nutrient values are logged as a 100 g basis.
actor FoodCatalogService {
    static let shared = FoodCatalogService()
    private let session: URLSession
    private let base = URL(string: "https://food-nutrition.canada.ca/api/canadian-nutrient-file/")!
    private var canadianFoodIndex: [CNFFood]?

    init(session: URLSession = .shared) { self.session = session }

    func search(_ query: String) async throws -> [FoodDefinition] {
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard term.count >= 2 else { return [] }
        async let cnf = searchCanadianNutrientFile(term)
        async let off = searchOpenFoodFacts(term)
        let cnfFoods = try? await cnf
        let offFoods = try? await off
        let values = (cnfFoods ?? []) + (offFoods ?? [])
        guard cnfFoods != nil || offFoods != nil else { throw FoodCatalogError.unavailable }
        var seen = Set<String>()
        return values.filter { seen.insert($0.id).inserted }
    }

    func lookupBarcode(_ rawCode: String) async throws -> FoodDefinition? {
        let code = rawCode.filter(\.isNumber)
        guard (8...14).contains(code.count) else { return nil }
        var components = URLComponents(string: "https://world.openfoodfacts.org/api/v2/product/\(code).json")!
        components.queryItems = [URLQueryItem(name: "fields", value: "code,product_name,brands,nutriments,serving_size,serving_quantity")]
        guard let url = components.url else { throw FoodCatalogError.invalidResponse }
        let data = try await get(url)
        return try Self.parseBarcodeResponse(data, requestedCode: code)
    }

    static func parseBarcodeResponse(_ data: Data, requestedCode: String) throws -> FoodDefinition? {
        let response = try JSONDecoder().decode(OFFProductResponse.self, from: data)
        guard response.status == 1, let product = response.product else { return nil }
        return product.definition(code: requestedCode)
    }

    private func searchCanadianNutrientFile(_ term: String) async throws -> [FoodDefinition] {
        let foods: [CNFFood]
        if let canadianFoodIndex {
            foods = canadianFoodIndex
        } else {
            var components = URLComponents(url: base.appendingPathComponent("food/"), resolvingAgainstBaseURL: false)!
            components.queryItems = [URLQueryItem(name: "lang", value: "en")]
            let data = try await get(components.url!)
            let index = try JSONDecoder().decode([CNFFood].self, from: data)
            canadianFoodIndex = index
            foods = index
        }
        let query = term.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        let matches = foods.filter {
            $0.description.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current).contains(query)
        }
        return try await withThrowingTaskGroup(of: FoodDefinition?.self) { group in
            for item in matches.prefix(10) {
                group.addTask { try await self.canonicalFood(item) }
            }
            var results: [FoodDefinition] = []
            for try await item in group { if let item { results.append(item) } }
            return results.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
    }

    private func canonicalFood(_ food: CNFFood) async throws -> FoodDefinition? {
        var components = URLComponents(url: base.appendingPathComponent("nutrientamount/"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "id", value: String(food.code)), URLQueryItem(name: "lang", value: "en")]
        let data = try await get(components.url!)
        let nutrients = try JSONDecoder().decode([CNFNutrient].self, from: data)
        let values = Dictionary(nutrients.map { ($0.id, $0.value) }, uniquingKeysWith: { first, _ in first })
        guard let calories = values[208], let protein = values[203], let carbs = values[205], let fat = values[204] else { return nil }
        return FoodDefinition(
            id: "cnf-\(food.code)", name: food.description, basisAmount: 100, basisUnit: "g",
            calories: calories, protein: protein, carbohydrates: carbs, fat: fat,
            source: "Canadian Nutrient File · Health Canada",
            sourceURL: "https://food-nutrition.canada.ca/cnf-fce/"
        )
    }

    private func searchOpenFoodFacts(_ term: String) async throws -> [FoodDefinition] {
        var components = URLComponents(string: "https://world.openfoodfacts.org/api/v2/search")!
        components.queryItems = [
            URLQueryItem(name: "search_terms", value: term),
            URLQueryItem(name: "fields", value: "code,product_name,brands,nutriments,serving_size,serving_quantity"),
            URLQueryItem(name: "page_size", value: "20")
        ]
        let data = try await get(components.url!)
        let response = try JSONDecoder().decode(OFFSearchResponse.self, from: data)
        return (response.products ?? []).compactMap { $0.definition(code: $0.code) }
    }

    private func get(_ url: URL) async throws -> Data {
        var request = URLRequest(url: url, timeoutInterval: 12)
        request.setValue("Logbook iOS/0.1 (food search)", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse, (200..<300).contains(response.statusCode) else {
            throw FoodCatalogError.unavailable
        }
        return data
    }
}

private struct CNFFood: Decodable {
    var code: Int
    var description: String
    enum CodingKeys: String, CodingKey { case code = "food_code", description = "food_description" }
}

private struct CNFNutrient: Decodable {
    var id: Int
    var value: Double
    enum CodingKeys: String, CodingKey { case id = "nutrient_name_id", value = "nutrient_value" }
}

private struct OFFSearchResponse: Decodable { var products: [OFFProduct]? }
private struct OFFProductResponse: Decodable { var status: Int?; var product: OFFProduct? }

private struct OFFProduct: Decodable {
    var code: String?
    var name: String?
    var brands: String?
    var servingSize: String?
    var servingQuantity: Double?
    var nutriments: [String: Double]?

    enum CodingKeys: String, CodingKey {
        case code
        case name = "product_name"
        case brands
        case servingSize = "serving_size"
        case servingQuantity = "serving_quantity"
        case nutriments
    }

    func definition(code override: String?) -> FoodDefinition? {
        guard let resolvedCode = override ?? self.code,
              let name = name?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty,
              let values = nutriments,
              let calories = values["energy-kcal_100g"], let protein = values["proteins_100g"],
              let carbs = values["carbohydrates_100g"], let fat = values["fat_100g"],
              [calories, protein, carbs, fat].allSatisfy({ $0.isFinite && $0 >= 0 }) else { return nil }
        let servingUnitIsGrams = servingSize?.range(of: #"\b\d+(?:[.,]\d+)?\s*g\b"#, options: .regularExpression) != nil
        let verifiedGrams = servingUnitIsGrams ? servingQuantity : nil
        let brand = brands?.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayName = [name, brand.flatMap { $0.isEmpty ? nil : $0 }].compactMap { $0 }.joined(separator: " · ")
        return FoodDefinition(
            id: "off-\(resolvedCode)", name: displayName, basisAmount: 100, basisUnit: "g",
            calories: calories, protein: protein, carbohydrates: carbs, fat: fat,
            source: "Open Food Facts · community-contributed",
            verifiedServingGrams: verifiedGrams,
            barcode: resolvedCode,
            sourceURL: "https://world.openfoodfacts.org/product/\(resolvedCode)"
        )
    }
}
