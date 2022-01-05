// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

class FilesExporter {

    public let name: String
    private let tempDirectoryURL: URL

    init(id: UUID = .init(), name: String, files: [File]) throws {
        self.name = name.withoutSlashes()
        self.tempDirectoryURL = FileManager.default
            .temporaryDirectory
            .appendingPathComponent(Bundle.main.bundleIdentifier!, isDirectory: true)
            .appendingPathComponent(id.uuidString, isDirectory: true)
        try? clearTempDirectory()
        try writeToTempDirectory(files: files)
    }

    deinit { try? clearTempDirectory() }
}

extension FilesExporter  {

#if os(macOS)
    func runExportInteraction(onQueue: DispatchQueue, didComplete: @escaping () -> Void) {
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
                    didComplete()
                    return
                }
                onQueue.async { [weak self] in
                    self?.export(to: url, didComplete: didComplete)
                }
            }
        }
    }
#elseif os(iOS)
    func runExportInteraction(onQueue: DispatchQueue, didComplete: @escaping () -> Void) {
        onQueue.async { [weak self] in
            guard let self = self else { return }
            let tempCopyURL = self.tempDirectoryURL
                .deletingLastPathComponent()
                .appendingPathComponent(self.name, isDirectory: true)

            try? FileManager.default.removeItem(at: tempCopyURL)
            try? FileManager.default.copyItem(at: self.tempDirectoryURL, to: tempCopyURL)

            let vc = UIActivityViewController(activityItems: [tempCopyURL], applicationActivities: nil)
            vc.modalPresentationStyle = .pageSheet
            
            DispatchQueue.main.async {
                let controller = UIApplication.shared.windows.first(where: \.isKeyWindow)?.rootViewController
                controller?.present(vc, animated: true, completion: didComplete)
            }
        }
    }
#endif

}

private extension FilesExporter {

    func clearTempDirectory() throws {
        try FileManager.default.removeItem(at: tempDirectoryURL)
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

    func export(to userURL: URL, didComplete: @escaping () -> Void) {
        do {
            var destination = userURL.appendingPathComponent(name, isDirectory: true)
            ensureDirectoryNameIsUnique(&destination)
            try FileManager.default.copyItem(at: tempDirectoryURL, to: destination)
        } catch { NSLog("\(Self.self) \(#function) \(error.localizedDescription)") }
        didComplete()
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
