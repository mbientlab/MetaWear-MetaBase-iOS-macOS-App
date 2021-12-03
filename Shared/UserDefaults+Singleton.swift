//  © 2021 Ryan Ferrell. github.com/importRyan


import Foundation
import CoreBluetooth
import MetaWear

// MARK: - Singleton UserDefaults (mirror original app)

let CurrentMetaBaseVersion = 5.0

public extension UserDefaults {

    fileprivate static let encoder = JSONEncoder()
    fileprivate static let decoder = JSONDecoder()

    enum Key: Codable {
        public typealias UUIDString = String
        case metadata(UUIDString)
        case groups
        case hasUsedMetaBaseVersion // Double

        public init(metadata peripheral: CBPeripheral) {
            self = Key.metadata(peripheral.identifier.uuidString)
        }

        public var value: String {
            switch self {
                case .groups: return "MetaWearGroup"
                case .metadata(let uuidString): return "MetaDataKey".appending(uuidString)
                case .hasUsedMetaBaseVersion: return "HasUsedMetaBaseVersion"
            }
        }
    }

    static func save<T: Encodable>(key: Key, value: T) {
        guard let data = try? Self.encoder.encode(value) else { return }
        UserDefaults.standard.set(data, forKey: key.value)
    }

    static func load<T: Decodable>(key: Key) -> T? {
        guard let data = UserDefaults.standard.value(forKey: key.value) as? Data
        else { return nil }
        return try? Self.decoder.decode(T.self, from: data)
    }

    /// Temporary to match prior app
    static func save<T: Encodable>(metadataKey: String, value: T) {
        guard let data = try? Self.encoder.encode(value) else { return }
        UserDefaults.standard.set(data, forKey: metadataKey)
    }

    
//    static func load(metadataKey: String) -> MetaWear.Metadata? {
//        guard let data = UserDefaults.standard.value(forKey: metadataKey) as? Data
//        else { return nil }
//        return try? Self.decoder.decode(MetaWear.Metadata.self, from: data)
//    }
}
