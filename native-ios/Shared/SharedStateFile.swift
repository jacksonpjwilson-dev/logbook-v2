import Foundation

enum SharedStateFile {
    static let appGroup = "group.com.example.logbook"
    static let fileName = "logbook-state-v1.json"

    static func containerURL(fileManager: FileManager = .default) -> URL {
        if let shared = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroup) {
            return shared
        }
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("Logbook", isDirectory: true)
    }

    static func fileURL(fileManager: FileManager = .default) -> URL {
        containerURL(fileManager: fileManager).appendingPathComponent(fileName)
    }

    static func load(fileManager: FileManager = .default) throws -> LogbookState {
        try LogbookRepository(url: fileURL(fileManager: fileManager), fileManager: fileManager).load()
    }

    static func save(_ state: LogbookState, fileManager: FileManager = .default) throws {
        try LogbookRepository(url: fileURL(fileManager: fileManager), fileManager: fileManager).save(state)
    }
}

struct LogbookRepository {
    let url: URL
    private let fileManager: FileManager

    init(url: URL, fileManager: FileManager = .default) {
        self.url = url
        self.fileManager = fileManager
    }

    static var shared: LogbookRepository { LogbookRepository(url: SharedStateFile.fileURL()) }

    func load() throws -> LogbookState {
        guard fileManager.fileExists(atPath: url.path) else { return .empty }
        let data = try Data(contentsOf: url)
        let state = try JSONDecoder.logbook.decode(LogbookState.self, from: data)
        guard state.schemaVersion == 1 else { throw StoreFileError.unsupportedSchema(state.schemaVersion) }
        return state
    }

    func save(_ state: LogbookState) throws {
        try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = try JSONEncoder.logbook.encode(state)
        try data.write(to: url, options: [.atomic, .completeFileProtectionUnlessOpen])
    }
}

enum StoreFileError: LocalizedError {
    case unsupportedSchema(Int)

    var errorDescription: String? {
        switch self {
        case .unsupportedSchema(let version): "This Logbook data file uses schema version \(version), which this build cannot safely edit. Export a backup and update the app before continuing."
        }
    }
}

extension JSONEncoder {
    static var logbook: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }
}

extension JSONDecoder {
    static var logbook: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
