import SwiftUI
import AppKit
import UniformTypeIdentifiers

@MainActor
final class AppViewModel: ObservableObject {
    @Published var sourcePath: String = ""
    @Published var destinationPath: String = ""
    @Published var maxWidthText: String = ""
    @Published var makeXlsx: Bool = false
    @Published var useUrlBase: Bool = false
    @Published var urlBase: String = ""

    @Published var statusText: String = "Ready"
    @Published var progressValue: Double = 0
    @Published var progressTotal: Double = 1
    @Published var logs: [String] = []
    @Published var isRunning: Bool = false

    private var task: Task<Void, Never>?

    func pickSourceFolder() {
        if let url = pickFolder(title: "Select source folder") {
            sourcePath = url.path
            if destinationPath.isEmpty {
                destinationPath = makeAutoDestination(for: url).path
            }
        }
    }

    func pickDestinationFolder() {
        if let url = pickFolder(title: "Select destination folder") {
            destinationPath = url.path
        }
    }

    func openInFinder(_ path: String) {
        guard !path.isEmpty else { return }
        NSWorkspace.shared.open(URL(fileURLWithPath: path))
    }

    func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { [weak self] item, _ in
            guard let self else { return }
            var url: URL?
            if let data = item as? Data {
                url = URL(dataRepresentation: data, relativeTo: nil)
            } else if let nsurl = item as? NSURL {
                url = nsurl as URL
            }
            guard let dropped = url else { return }
            let folder = dropped.hasDirectoryPath ? dropped : dropped.deletingLastPathComponent()
            Task { @MainActor in
                self.sourcePath = folder.path
                if self.destinationPath.isEmpty {
                    self.destinationPath = self.makeAutoDestination(for: folder).path
                }
            }
        }
        return true
    }

    func start() {
        guard !isRunning else { return }
        guard !sourcePath.isEmpty, !destinationPath.isEmpty else {
            appendLog("Please select source and destination.")
            return
        }

        let src = URL(fileURLWithPath: sourcePath)
        let dst = URL(fileURLWithPath: destinationPath)

        guard src != dst else {
            appendLog("Source and destination must differ.")
            return
        }

        let maxWidth: Int?
        if maxWidthText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            maxWidth = nil
        } else if let v = Int(maxWidthText), v > 0 {
            maxWidth = v
        } else {
            appendLog("Max width must be a positive integer.")
            return
        }

        if makeXlsx && useUrlBase && urlBase.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            appendLog("URL base is required when URL mode is enabled.")
            return
        }

        logs.removeAll()
        statusText = "Starting..."
        progressValue = 0
        progressTotal = 1
        isRunning = true

        task = Task {
            let config = ConversionConfig(
                source: src,
                destination: dst,
                maxWidth: maxWidth,
                makeXlsx: makeXlsx,
                useUrlBase: useUrlBase,
                urlBase: urlBase
            )

            do {
                try await Converter.run(config: config) { [weak self] event in
                    guard let self else { return }
                    switch event {
                    case .progress(let done, let total, let status):
                        self.progressValue = Double(done)
                        self.progressTotal = Double(max(total, 1))
                        self.statusText = status
                    case .log(let line):
                        self.appendLog(line)
                    case .finished(let summary):
                        self.appendLog(summary)
                        self.statusText = "Done"
                    }
                }
            } catch {
                appendLog("Failed: \(error.localizedDescription)")
                statusText = "Failed"
            }

            isRunning = false
            task = nil
        }
    }

    func cancel() {
        task?.cancel()
        appendLog("Cancelling...")
    }

    private func appendLog(_ line: String) {
        logs.append(line)
    }

    private func pickFolder(title: String) -> URL? {
        let panel = NSOpenPanel()
        panel.title = title
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        return panel.runModal() == .OK ? panel.url : nil
    }

    private func makeAutoDestination(for source: URL) -> URL {
        let parent = source.deletingLastPathComponent()
        let baseName = source.lastPathComponent + " webp"
        var candidate = parent.appendingPathComponent(baseName, isDirectory: true)
        var idx = 2
        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = parent.appendingPathComponent("\(baseName)_\(idx)", isDirectory: true)
            idx += 1
        }
        return candidate
    }
}
