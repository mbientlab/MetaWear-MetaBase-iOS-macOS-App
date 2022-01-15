// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation

public enum ImportError: Error, LocalizedError, Equatable {
    case noMetaBase4MetadataToImport
    case alreadyImportedDataFromThisDevice
    case unexpected(Error)


    public var errorDescription: String? {
        switch self {
            case .noMetaBase4MetadataToImport: return "No MetaBase 4 session data found. Try importing from another iOS device."
            case .alreadyImportedDataFromThisDevice: return "Already imported MetaBase 4 session data from this device."
            case .unexpected(let error): return error.localizedDescription
        }
    }

    public static func == (lhs: ImportError, rhs: ImportError) -> Bool {
        switch (lhs, rhs) {
            case (.noMetaBase4MetadataToImport, .noMetaBase4MetadataToImport), (.alreadyImportedDataFromThisDevice, .alreadyImportedDataFromThisDevice): return true
            case (.unexpected(let left), .unexpected(let right)):
                return left.localizedDescription == right.localizedDescription
            default: return false
        }
    }
}
