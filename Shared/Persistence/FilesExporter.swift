// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif
import mbientSwiftUI

class FilesExporter {

    public let id: UUID
    public let name: String
    private let tempDirectoryURL: URL

    init(id: UUID = .init(), name: String, files: [File]) throws {
        self.id = id
        self.name = name.withoutSlashes()
        self.tempDirectoryURL = FileManager.default
            .temporaryDirectory
            .appendingPathComponent(Bundle.main.bundleIdentifier!, isDirectory: true)
            .appendingPathComponent(id.uuidString, isDirectory: true)
        clearTempDirectory()
        try writeToTempDirectory(files: files)
    }

    deinit { clearTempDirectory() }
}

extension FilesExporter  {

#if os(macOS)
    /// On macOS, handles presenting an NSOpenPanel from the key window, providing the user-selected URL after files are copied to the chosen location. If the user dismisses/cancels the save, the url returned will be nil.
    ///
    func runExportInteraction(
        onQueue: DispatchQueue,
        didExport: @escaping (Result<URL?,Error>) -> Void
    ) {
        DispatchQueue.main.async { [weak self]  in
            guard let self = self else { return }
            guard let window = NSApp.keyWindow else { return }
            let panel = NSOpenPanel()
            panel.canChooseDirectories = true
            panel.canCreateDirectories = true
            panel.allowedFileTypes = ["none"]
            panel.allowsOtherFileTypes = false
            panel.allowsMultipleSelection = false
            panel.prompt = "Export"
            panel.message = "Select a folder to save files from \(self.name)"

            panel.beginSheetModal(for: window) { [weak self] response in
                guard response == .OK, let url = panel.url else {
                    didExport(.success(nil))
                    return
                }
                onQueue.async { [weak self] in
                    self?.export(to: url, didComplete: didExport)
                }
            }
        }
    }
#elseif os(iOS)
    /// On iOS, provides a URL that can be used for a Files exporter or UIActivityViewController.
    ///
    /// To properly situate that controller for iPad modal presentation, the precipitating view should handle the presentation to ensure the location is accurate at the arbitrary future presentation time (e.g., view may have scrolled or this export's presentation is delayed in a queue).
    ///
    func runExportInteraction(
        onQueue: DispatchQueue,
        shareableItem: @escaping (Result<URL,Error>) -> Void
    ) {
        onQueue.async { [weak self] in
            guard let self = self else { return }
            let tempCopyURL = self.tempDirectoryURL
                .deletingLastPathComponent()
                .appendingPathComponent(self.name, isDirectory: true)

            do {
                try? FileManager.default.removeItem(at: tempCopyURL)
                try FileManager.default.copyItem(at: self.tempDirectoryURL, to: tempCopyURL)
                shareableItem(.success(tempCopyURL))

            } catch { shareableItem(.failure(error)) }
        }
    }
#endif
}

private extension FilesExporter {

    func clearTempDirectory() {
        try? FileManager.default.removeItem(at: tempDirectoryURL)
    }

    func writeToTempDirectory(files: [File]) throws {
        try FileManager.default.createDirectory(
            at: tempDirectoryURL,
            withIntermediateDirectories: true,
            attributes: nil
        )

        for file in files {
            let fileURL = tempDirectoryURL
                .appendingPathComponent(file.name)
                .appendingPathExtension("csv")
            try? FileManager.default.removeItem(at: fileURL)
            try file.csv.write(to: fileURL, options: .atomic)
        }
    }

    func export(to userURL: URL, didComplete: @escaping (Result<URL?,Error>) -> Void) {
        do {
            var destination = userURL.appendingPathComponent(name, isDirectory: true)
            ensureDirectoryNameIsUnique(&destination)
            try FileManager.default.copyItem(at: tempDirectoryURL, to: destination)
            didComplete(.success(destination))
        } catch { didComplete(.failure(error)) }
    }

    func ensureDirectoryNameIsUnique(_ url: inout URL) {
        var collisions = 1
        while FileManager.default.fileExists(atPath: url.path) {
            collisions += 1
            url.deleteLastPathComponent()
            url.appendPathComponent(name + " \(collisions)", isDirectory: true)
        }
    }
}

extension String {
    func withoutSlashes() -> String {
        self
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: ":", with: "-")
            .replacingOccurrences(of: "/", with: ":")
    }
}

