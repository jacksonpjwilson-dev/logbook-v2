import Foundation
import XCTest
@testable import Logbook

final class FoodCatalogServiceTests: XCTestCase {
    override func tearDown() {
        FoodURLProtocolStub.handler = nil
        super.tearDown()
    }

    func testSearchMergesCanadianNutrientFileAndOpenFoodFactsResults() async throws {
        FoodURLProtocolStub.handler = { request in
            let userAgent = request.value(forHTTPHeaderField: "User-Agent") ?? ""
            XCTAssertTrue(userAgent.hasPrefix("Logbook/"), "Provider requests identify the app and version")
            XCTAssertTrue(userAgent.contains("github.com/jacksonpjwilson-dev/logbook-v2"), "Provider requests contain a contact URL")
            let path = request.url?.path.lowercased() ?? ""
            if path.contains("/nutrientamount") {
                return Self.response(request, status: 200, body: #"""
                [
                    {"nutrient_name_id":208,"nutrient_value":89},
                    {"nutrient_name_id":203,"nutrient_value":1.1},
                    {"nutrient_name_id":205,"nutrient_value":22.8},
                    {"nutrient_name_id":204,"nutrient_value":0.3}
                ]
                """#)
            }
            if path.contains("/food") {
                return Self.response(request, status: 200, body: #"[{"food_code":1,"food_description":"Banana, raw"}]"#)
            }
            if path == "/cgi/search.pl" {
                let queryItems = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems ?? []
                XCTAssertEqual(queryItems.first(where: { $0.name == "search_terms" })?.value, "banana")
                XCTAssertEqual(queryItems.first(where: { $0.name == "action" })?.value, "process")
                XCTAssertEqual(queryItems.first(where: { $0.name == "json" })?.value, "1")
                return Self.response(request, status: 200, body: #"""
                {"products":[
                    {"code":"0123456789012","product_name":"Banana chips","brands":"QA Foods",
                     "serving_size":"30 g","serving_quantity":30,
                     "nutriments":{"energy-kcal_100g":519,"proteins_100g":2.3,"carbohydrates_100g":58,"fat_100g":33}}
                ]}
                """#)
            }
            return Self.response(request, status: 404, body: "{}")
        }

        let service = FoodCatalogService(session: Self.stubbedSession())
        let foods = try await service.search("banana")

        XCTAssertEqual(Set(foods.map(\.id)), ["cnf-1", "off-0123456789012"])
        let banana = try XCTUnwrap(foods.first { $0.id == "cnf-1" })
        XCTAssertEqual(banana.calories, 89)
        XCTAssertEqual(banana.basisAmount, 100)
        XCTAssertEqual(banana.basisUnit, "g")
        XCTAssertEqual(banana.source, "Canadian Nutrient File · Health Canada")

        let packaged = try XCTUnwrap(foods.first { $0.id == "off-0123456789012" })
        XCTAssertEqual(packaged.calories, 519)
        XCTAssertEqual(packaged.verifiedServingGrams, 30)
        XCTAssertEqual(packaged.source, "Open Food Facts · community-contributed")
        XCTAssertTrue(packaged.sourceURL?.contains("world.openfoodfacts.org/product/") == true)
    }

    func testSearchUsesAvailableProviderWhenOtherProviderIsOffline() async throws {
        FoodURLProtocolStub.handler = { request in
            guard request.url?.host == "world.openfoodfacts.org" else {
                return Self.response(request, status: 503, body: "{}")
            }
            return Self.response(request, status: 200, body: #"""
            {"products":[
                {"code":"0123456789012","product_name":"QA oats",
                 "nutriments":{"energy-kcal_100g":380,"proteins_100g":13,"carbohydrates_100g":68,"fat_100g":7}}
            ]}
            """#)
        }

        let service = FoodCatalogService(session: Self.stubbedSession())
        let foods = try await service.search("oats")

        XCTAssertEqual(foods.map(\.id), ["off-0123456789012"], "One functioning public provider should still return usable foods")
    }

    func testSearchReportsUnavailableOnlyWhenBothProvidersFail() async {
        FoodURLProtocolStub.handler = { request in Self.response(request, status: 503, body: "{}") }
        let service = FoodCatalogService(session: Self.stubbedSession())

        do {
            _ = try await service.search("oats")
            XCTFail("Both unavailable providers must produce the offline-search error")
        } catch let error as FoodCatalogError {
            guard case .unavailable = error else { return XCTFail("Unexpected Food catalog error: \(error)") }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    @MainActor
    func testLiveProviderSearchParsingAndDiskCache() async throws {
        guard ProcessInfo.processInfo.environment["LOGBOOK_LIVE_PROVIDER_TESTS"] == "1" else {
            throw XCTSkip("Live provider requests run only in the dedicated provider-validation workflow.")
        }

        let service = FoodCatalogService()
        let canadianFoods = try await service.searchCanadianNutrientFile("banana")
        XCTAssertFalse(canadianFoods.isEmpty, "CNF should return live banana data through Logbook's parser.")
        XCTAssertTrue(canadianFoods.allSatisfy {
            $0.source == "Canadian Nutrient File · Health Canada" &&
            $0.sourceURL?.contains("food-nutrition.canada.ca") == true &&
            $0.basisAmount == 100 && $0.basisUnit == "g" &&
            [$0.calories, $0.protein, $0.carbohydrates, $0.fat].allSatisfy { $0.isFinite && $0 >= 0 }
        }, "CNF values should retain provenance and valid per-100-g nutrients.")

        let openFoodFacts = try await service.searchOpenFoodFacts("banana")
        XCTAssertFalse(openFoodFacts.isEmpty, "Open Food Facts should return live search results through Logbook's parser.")
        XCTAssertTrue(openFoodFacts.allSatisfy {
            $0.source == "Open Food Facts · community-contributed" &&
            $0.sourceURL?.hasPrefix("https://world.openfoodfacts.org/product/") == true &&
            $0.basisAmount == 100 && $0.basisUnit == "g" &&
            [$0.calories, $0.protein, $0.carbohydrates, $0.fat].allSatisfy { $0.isFinite && $0 >= 0 }
        }, "Open Food Facts values should retain product provenance and valid per-100-g nutrients.")
        XCTAssertTrue(openFoodFacts.allSatisfy { food in
            food.verifiedServingGrams == nil || food.verifiedServingGrams!.isFinite && food.verifiedServingGrams! > 0
        }, "Only positive gram servings should be cached as verified serving sizes.")

        let foodsToCache = canadianFoods + openFoodFacts
        let cacheURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("LogbookLiveProvider-\(UUID().uuidString)", isDirectory: true)
            .appendingPathComponent("state.json")
        let store = LogbookStore(repository: LogbookRepository(url: cacheURL))
        store.cacheFoodDefinitions(foodsToCache)
        let reloaded = LogbookStore(repository: LogbookRepository(url: cacheURL)).state.nutrition.foods
        let cachedByID = Dictionary(uniqueKeysWithValues: reloaded.map { ($0.id, $0) })
        for food in foodsToCache {
            let cached = try XCTUnwrap(cachedByID[food.id], "Imported food \(food.id) should survive a disk reload.")
            XCTAssertEqual(cached.source, food.source)
            XCTAssertEqual(cached.sourceURL, food.sourceURL)
            XCTAssertEqual(cached.calories, food.calories, accuracy: 0.001)
            XCTAssertEqual(cached.protein, food.protein, accuracy: 0.001)
            XCTAssertEqual(cached.carbohydrates, food.carbohydrates, accuracy: 0.001)
            XCTAssertEqual(cached.fat, food.fat, accuracy: 0.001)
        }
    }

    private static func stubbedSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [FoodURLProtocolStub.self]
        return URLSession(configuration: configuration)
    }

    private static func response(_ request: URLRequest, status: Int, body: String) -> (HTTPURLResponse, Data) {
        (HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: "HTTP/1.1", headerFields: nil)!, Data(body.utf8))
    }
}

private final class FoodURLProtocolStub: URLProtocol {
    private static let lock = NSLock()
    private static var storedHandler: ((URLRequest) -> (HTTPURLResponse, Data))?
    static var handler: ((URLRequest) -> (HTTPURLResponse, Data))? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return storedHandler
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            storedHandler = newValue
        }
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let handler = Self.handler
        guard let handler else {
            client?.urlProtocol(self, didFailWithError: FoodCatalogError.unavailable)
            return
        }
        let (response, data) = handler(request)
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
