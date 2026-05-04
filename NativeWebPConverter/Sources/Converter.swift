import Foundation
import ImageIO
import UniformTypeIdentifiers
import CoreGraphics

struct ConversionConfig {
    let source: URL
    let destination: URL
    let maxWidth: Int?
    let makeXlsx: Bool
    let useUrlBase: Bool
    let urlBase: String
}

enum ConversionEvent {
    case progress(done: Int, total: Int, status: String)
    case log(String)
    case finished(String)
}

enum Converter {
    private static let imageExts: Set<String> = ["jpg", "jpeg", "png", "bmp", "tif", "tiff", "gif", "webp"]
    private static let videoExts: Set<String> = ["mp4", "mov", "avi", "mkv"]

    static func run(config: ConversionConfig, onEvent: @escaping @MainActor (ConversionEvent) -> Void) async throws {
        try FileManager.default.createDirectory(at: config.destination, withIntermediateDirectories: true)

        let allFiles = collectFiles(in: config.source)
            .filter { isImage($0) || isVideo($0) }

        if allFiles.isEmpty {
            await onEvent(.log("No images or videos found."))
            await onEvent(.progress(done: 0, total: 1, status: "No files found"))
            return
        }

        var converted = 0
        var copiedWebp = 0
        var copiedVideos = 0
        var errors = 0
        var indexed: [(String, String)] = []

        await onEvent(.progress(done: 0, total: allFiles.count, status: "Found \(allFiles.count) files"))

        for (idx, file) in allFiles.enumerated() {
            try Task.checkCancellation()
            do {
                let rel = file.path.replacingOccurrences(of: config.source.path + "/", with: "")
                let dst = config.destination.appendingPathComponent(rel)

                if isVideo(file) {
                    try copyFile(file, to: dst)
                    copiedVideos += 1
                    await onEvent(.log("VIDEO copied: \(file.lastPathComponent)"))
                } else if isImage(file) {
                    if file.pathExtension.lowercased() == "webp" {
                        try copyFile(file, to: dst)
                        copiedWebp += 1
                        await onEvent(.log("WEBP copied: \(file.lastPathComponent)"))
                        if config.makeXlsx {
                            indexed.append((dst.deletingPathExtension().lastPathComponent, indexPath(for: dst, config: config)))
                        }
                    } else {
                        let dstWebp = dst.deletingPathExtension().appendingPathExtension("webp")
                        try convertImageToWebP(source: file, destination: dstWebp, maxWidth: config.maxWidth)
                        converted += 1
                        await onEvent(.log("IMAGE converted: \(file.lastPathComponent)"))
                        if config.makeXlsx {
                            indexed.append((dstWebp.deletingPathExtension().lastPathComponent, indexPath(for: dstWebp, config: config)))
                        }
                    }
                }
            } catch {
                errors += 1
                await onEvent(.log("FAILED: \(file.lastPathComponent) - \(error.localizedDescription)"))
            }

            let done = idx + 1
            let status = "Processed \(done)/\(allFiles.count)  images:\(converted) webp:\(copiedWebp) videos:\(copiedVideos) errors:\(errors)"
            await onEvent(.progress(done: done, total: allFiles.count, status: status))
        }

        if config.makeXlsx, !indexed.isEmpty {
            let xlsx = config.destination.appendingPathComponent("converted_images.xlsx")
            try writeMinimalXlsx(rows: indexed, output: xlsx)
            await onEvent(.log("XLSX saved: \(xlsx.path)"))
        }

        let summary = "Done. Converted: \(converted), WEBP copied: \(copiedWebp), videos: \(copiedVideos), errors: \(errors)"
        await onEvent(.finished(summary))
    }

    private static func collectFiles(in root: URL) -> [URL] {
        let keys: [URLResourceKey] = [.isRegularFileKey]
        guard let en = FileManager.default.enumerator(at: root, includingPropertiesForKeys: keys, options: [.skipsHiddenFiles]) else {
            return []
        }
        var out: [URL] = []
        for case let url as URL in en {
            if (try? url.resourceValues(forKeys: Set(keys)).isRegularFile) == true {
                out.append(url)
            }
        }
        return out
    }

    private static func isImage(_ url: URL) -> Bool { imageExts.contains(url.pathExtension.lowercased()) }
    private static func isVideo(_ url: URL) -> Bool { videoExts.contains(url.pathExtension.lowercased()) }

    private static func copyFile(_ src: URL, to dst: URL) throws {
        try FileManager.default.createDirectory(at: dst.deletingLastPathComponent(), withIntermediateDirectories: true)
        if FileManager.default.fileExists(atPath: dst.path) {
            try FileManager.default.removeItem(at: dst)
        }
        try FileManager.default.copyItem(at: src, to: dst)
    }

    private static func convertImageToWebP(source: URL, destination: URL, maxWidth: Int?) throws {
        guard let src = CGImageSourceCreateWithURL(source as CFURL, nil) else {
            throw NSError(domain: "WebPConverter", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cannot read image"]) 
        }

        let image: CGImage?
        if let maxWidth, maxWidth > 0 {
            let options: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: maxWidth
            ]
            image = CGImageSourceCreateThumbnailAtIndex(src, 0, options as CFDictionary)
        } else {
            image = CGImageSourceCreateImageAtIndex(src, 0, nil)
        }

        guard let cgImage = image else {
            throw NSError(domain: "WebPConverter", code: 2, userInfo: [NSLocalizedDescriptionKey: "Cannot decode image"]) 
        }

        try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)

        guard let dest = CGImageDestinationCreateWithURL(destination as CFURL, UTType.webP.identifier as CFString, 1, nil) else {
            throw NSError(domain: "WebPConverter", code: 3, userInfo: [NSLocalizedDescriptionKey: "Cannot create WEBP destination"]) 
        }

        var props: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: 0.85
        ]

        if let metadata = CGImageSourceCopyPropertiesAtIndex(src, 0, nil) as? [CFString: Any] {
            for (k, v) in metadata where props[k] == nil {
                props[k] = v
            }
        }

        CGImageDestinationAddImage(dest, cgImage, props as CFDictionary)
        guard CGImageDestinationFinalize(dest) else {
            throw NSError(domain: "WebPConverter", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to write WEBP"]) 
        }
    }

    private static func indexPath(for file: URL, config: ConversionConfig) -> String {
        if config.useUrlBase {
            let base = config.urlBase.hasSuffix("/") ? config.urlBase : config.urlBase + "/"
            return base + file.lastPathComponent
        }
        return file.path
    }

    // Minimal XLSX writer (A: filename, B: path/url)
    private static func writeMinimalXlsx(rows: [(String, String)], output: URL) throws {
        let tmp = output.deletingLastPathComponent().appendingPathComponent(".xlsx_tmp_\(UUID().uuidString)", isDirectory: true)
        let fm = FileManager.default
        try fm.createDirectory(at: tmp, withIntermediateDirectories: true)

        let rels = tmp.appendingPathComponent("_rels", isDirectory: true)
        let xl = tmp.appendingPathComponent("xl", isDirectory: true)
        let xlRels = xl.appendingPathComponent("_rels", isDirectory: true)
        let ws = xl.appendingPathComponent("worksheets", isDirectory: true)
        try fm.createDirectory(at: rels, withIntermediateDirectories: true)
        try fm.createDirectory(at: xlRels, withIntermediateDirectories: true)
        try fm.createDirectory(at: ws, withIntermediateDirectories: true)

        try xmlRootRels().write(to: rels.appendingPathComponent(".rels"), atomically: true, encoding: .utf8)
        try xmlContentTypes().write(to: tmp.appendingPathComponent("[Content_Types].xml"), atomically: true, encoding: .utf8)
        try xmlWorkbook().write(to: xl.appendingPathComponent("workbook.xml"), atomically: true, encoding: .utf8)
        try xmlWorkbookRels().write(to: xlRels.appendingPathComponent("workbook.xml.rels"), atomically: true, encoding: .utf8)
        try xmlSheet(rows: rows).write(to: ws.appendingPathComponent("sheet1.xml"), atomically: true, encoding: .utf8)

        if fm.fileExists(atPath: output.path) { try fm.removeItem(at: output) }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
        process.currentDirectoryURL = tmp
        process.arguments = ["-q", "-r", output.path, "."]
        try process.run()
        process.waitUntilExit()
        if process.terminationStatus != 0 {
            throw NSError(domain: "WebPConverter", code: 5, userInfo: [NSLocalizedDescriptionKey: "zip failed creating xlsx"])
        }

        try? fm.removeItem(at: tmp)
    }

    private static func xmlRootRels() -> String {
        """
        <?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>
        <Relationships xmlns=\"http://schemas.openxmlformats.org/package/2006/relationships\">
          <Relationship Id=\"rId1\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument\" Target=\"xl/workbook.xml\"/>
        </Relationships>
        """
    }

    private static func xmlContentTypes() -> String {
        """
        <?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>
        <Types xmlns=\"http://schemas.openxmlformats.org/package/2006/content-types\">
          <Default Extension=\"rels\" ContentType=\"application/vnd.openxmlformats-package.relationships+xml\"/>
          <Default Extension=\"xml\" ContentType=\"application/xml\"/>
          <Override PartName=\"/xl/workbook.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml\"/>
          <Override PartName=\"/xl/worksheets/sheet1.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml\"/>
        </Types>
        """
    }

    private static func xmlWorkbook() -> String {
        """
        <?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>
        <workbook xmlns=\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\" xmlns:r=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships\">
          <sheets>
            <sheet name=\"Images\" sheetId=\"1\" r:id=\"rId1\"/>
          </sheets>
        </workbook>
        """
    }

    private static func xmlWorkbookRels() -> String {
        """
        <?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>
        <Relationships xmlns=\"http://schemas.openxmlformats.org/package/2006/relationships\">
          <Relationship Id=\"rId1\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet\" Target=\"worksheets/sheet1.xml\"/>
        </Relationships>
        """
    }

    private static func xmlSheet(rows: [(String, String)]) -> String {
        var xml = """
        <?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>
        <worksheet xmlns=\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\">
          <sheetData>
            <row r=\"1\">
              <c r=\"A1\" t=\"inlineStr\"><is><t>filename</t></is></c>
              <c r=\"B1\" t=\"inlineStr\"><is><t>path</t></is></c>
            </row>
        """
        for (i, row) in rows.enumerated() {
            let r = i + 2
            let a = xmlEsc(row.0)
            let b = xmlEsc(row.1)
            xml += "\n<row r=\"\(r)\"><c r=\"A\(r)\" t=\"inlineStr\"><is><t>\(a)</t></is></c><c r=\"B\(r)\" t=\"inlineStr\"><is><t>\(b)</t></is></c></row>"
        }
        xml += "\n  </sheetData>\n</worksheet>\n"
        return xml
    }

    private static func xmlEsc(_ s: String) -> String {
        s
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}
