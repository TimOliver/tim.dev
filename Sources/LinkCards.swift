// tim.dev - released into the public domain. No rights reserved.

import AppKit
import CoreImage
import CryptoKit
import Foundation
import SwiftSoup

/// Link cards (og:image) in the style of Apple's WWDC/Tech Talk title cards:
/// the wordmark top-left, the title and a subtitle, and a byline (Tim's
/// name, plus the date on posts) bottom-left. The background is dark grey, or a dimmed, blurred copy of the
/// page's lead image when it has one.
///
/// - Posts: the date joins the byline ("Tim Oliver · 21 June 2015"); the
///   subtitle is the post's `subtitle:`, or for older posts the part of the
///   title after a spaced dash.
///   The image is the post's `image:`.
///   MainLayout points og:image at the card (see `url(forPostPath:)`).
/// - Every other page except home and the 404: the subtitle is the page's
///   tagline and the image the one marked `data-link-card`, else its existing
///   og:image or first content image.
///   These are read from the built HTML, whose og:image is then rewritten.
///
/// Rendered by a post-publish pass into `Build/img/cards/`. Finished cards are
/// cached in `.build/link-cards/`, keyed by everything that goes into them, so
/// a normal build only renders new or changed cards.
enum LinkCards {

    /// Bump to re-render every card after changing the design below.
    static let version = 12

    static let size = CGSize(width: 1200, height: 630)

    /// The site-relative URL of a page's card: `/2017/09/19/slug/` becomes
    /// `/img/cards/2017-09-19-slug.jpg`. MainLayout and the renderer both
    /// derive the name from the page path, so they can't drift apart.
    static func url(forPostPath path: String) -> String {
        let name = path.split(separator: "/").joined(separator: "-")
        return "/img/cards/\(name).jpg"
    }

    // MARK: - Build pass

    /// Renders (or copies from the cache) every card.
    static func render(root: URL, siteURL: URL) throws {
        var renderer = try Renderer(root: root)
        try renderer.posts()
        try renderer.pages(siteURL: siteURL)
        if renderer.rendered > 0 { print("Link cards: rendered \(renderer.rendered)") }
    }

    private struct Renderer {
        let root: URL
        let build: URL
        let cache: URL
        let logo: NSImage
        var rendered = 0
        private let fm = FileManager.default

        init(root: URL) throws {
            self.root = root
            build = root.appending(path: "Build")
            cache = root.appending(path: ".build/link-cards")
            try fm.createDirectory(at: build.appending(path: "img/cards"), withIntermediateDirectories: true)
            try fm.createDirectory(at: cache, withIntermediateDirectories: true)
            logo = try wordmark(root: root)
        }

        /// One card per published post, from its front matter.
        mutating func posts() throws {
            let folder = root.appending(path: "Content/posts")
            for name in try fm.contentsOfDirectory(atPath: folder.path).sorted() where name.hasSuffix(".md") {
                let meta = try frontMatter(folder.appending(path: name))
                guard meta["published"] != "false",
                      let title = meta["title"], let path = meta["path"], let date = meta["date"] else { continue }
                // The tagline is the post's `subtitle:` (shown under the title
                // on the page too). Older posts carry theirs after a spaced
                // dash instead ("TOCropViewController – An open source image
                // cropper for iOS"), so split on that when there's no subtitle.
                var heading = title, subtitle = meta["subtitle"] ?? ""
                if subtitle.isEmpty, let dash = title.range(of: #" [–—] "#, options: .regularExpression) {
                    heading = String(title[..<dash.lowerBound])
                    subtitle = String(title[dash.upperBound...])
                }
                try make(date: formattedDate(date), title: heading, subtitle: subtitle,
                         image: meta["image"].map { root.appending(path: "Assets" + $0) },
                         path: path)
            }
        }

        /// One card per other page, read from its built HTML.
        mutating func pages(siteURL: URL) throws {
            let site = siteURL.absoluteString.hasSuffix("/") ? String(siteURL.absoluteString.dropLast()) : siteURL.absoluteString
            guard let files = fm.enumerator(at: build, includingPropertiesForKeys: nil) else { return }
            for case let file as URL in files where file.lastPathComponent == "index.html" {
                let path = String(file.deletingLastPathComponent().path.dropFirst(build.path.count)) + "/"
                let section = path.split(separator: "/").first.map(String.init) ?? ""
                // Home keeps the plain card; posts were done above.
                if section.isEmpty || (section.count == 4 && section.allSatisfy(\.isNumber)) { continue }

                var html = try String(contentsOf: file, encoding: .utf8)
                let doc = try SwiftSoup.parse(html)
                let ogTitle = try doc.select("meta[property=og:title]").attr("content")
                let title = ogTitle.replacingOccurrences(of: " - [tim.dev]", with: "")
                let subtitle = try ["main .page-subtitle", "main .collection-detail-tagline", "main .about-section-subtitle"]
                    .lazy.compactMap { try doc.select($0).first()?.text() }.first ?? ""

                // Lead image: one the page marks with `data-link-card`, else
                // its own og:image, else its first real content image (not an
                // LQIP data URI or an SVG badge).
                var src = try doc.select("main img[data-link-card]").first()?.attr("src")
                    ?? doc.select("meta[property=og:image]").attr("content")
                if src.hasSuffix("/img/site/link-card.png") {
                    src = try doc.select("main img[src]").array()
                        .map { try $0.attr("src") }
                        .first { !$0.hasPrefix("data:") && !$0.hasSuffix(".svg") } ?? ""
                }
                src = src.replacingOccurrences(of: site, with: "")
                let image = src.hasPrefix("/") ? build.appending(path: src.removingPercentEncoding ?? src) : nil

                let card = try make(title: title, subtitle: subtitle, image: image, path: path)
                let tag = try NSRegularExpression(pattern: #"(<meta property="og:image" content=")[^"]*""#)
                let range = NSRange(html.startIndex..., in: html)
                html = tag.stringByReplacingMatches(in: html, range: range,
                                                    withTemplate: "$1\(NSRegularExpression.escapedTemplate(for: site + card))\"")
                try html.write(to: file, atomically: true, encoding: .utf8)
            }
        }

        /// Copies the card for these inputs into Build/, rendering it first if
        /// the cache doesn't have it. Returns its site-relative URL.
        @discardableResult
        mutating func make(date: String = "", title: String, subtitle: String, image: URL?,
                           path: String) throws -> String {
            // Cache key: the design version plus every input. The image is
            // keyed by size and modification date rather than its bytes, so
            // checking the cache doesn't mean reading every photo.
            var key = "\(version)|\(date)|\(title)|\(subtitle)"
            if let image, let attrs = try? fm.attributesOfItem(atPath: image.path) {
                key += "|\(image.path)|\(attrs[.size] ?? "")|\(attrs[.modificationDate] ?? "")"
            }
            let digest = SHA256.hash(data: Data(key.utf8)).map { String(format: "%02x", $0) }.joined()
            let cached = cache.appending(path: "\(digest).jpg")

            if !fm.fileExists(atPath: cached.path) {
                let background = image.flatMap { NSImage(contentsOf: $0)?.cgImage(forProposedRect: nil, context: nil, hints: nil) }
                if let image, background == nil {
                    print("Link card: couldn't read \(image.path) for \(path); using plain background")
                }
                try card(date: date, title: title, subtitle: subtitle, background: background, logo: logo)
                    .write(to: cached)
                rendered += 1
            }

            let url = LinkCards.url(forPostPath: path)
            let target = build.appending(path: url)
            try? fm.removeItem(at: target)
            try fm.copyItem(at: cached, to: target)
            return url
        }
    }

    // MARK: - Drawing

    private static let margin: CGFloat = 72

    /// Draws one card and returns it as JPEG data (PNG photo cards ran ~230 KB).
    static func card(date: String, title: String, subtitle: String, background: CGImage?,
                     logo: NSImage) throws -> Data {
        let width = Int(size.width), height = Int(size.height)
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height,
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0),
              let context = NSGraphicsContext(bitmapImageRep: rep) else {
            throw CocoaError(.fileWriteUnknown)
        }

        NSGraphicsContext.saveGraphicsState()
        defer { NSGraphicsContext.restoreGraphicsState() }
        NSGraphicsContext.current = context
        let canvas = CGRect(origin: .zero, size: size)

        // Background: dark grey, or the blurred photo dimmed until white text
        // reads clearly on it (brighter photos get a heavier dim).
        NSColor(srgbRed: 0x1c / 255, green: 0x1c / 255, blue: 0x1e / 255, alpha: 1).setFill()
        canvas.fill()
        if let background, let photo = blurred(background) {
            context.cgContext.interpolationQuality = .high
            context.cgContext.draw(photo.image, in: canvas)
            NSColor(white: 0, alpha: max(0.55, 1 - 0.16 / max(photo.luminance, 0.01))).setFill()
            canvas.fill(using: .sourceOver)
        }

        // Everything else is laid out top-down, so flip to a top-left origin.
        let cg = context.cgContext
        cg.translateBy(x: 0, y: size.height)
        cg.scaleBy(x: 1, y: -1)
        NSGraphicsContext.current = NSGraphicsContext(cgContext: cg, flipped: true)

        // Wordmark, top-left.
        let logoHeight: CGFloat = 34
        let logoWidth = logoHeight * logo.size.width / logo.size.height
        logo.draw(in: CGRect(x: margin, y: 64, width: logoWidth, height: logoHeight),
                  from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)

        // Byline at the bottom: who, and on posts when.
        let name = NSMutableAttributedString(attributedString: text("Tim Oliver", size: 28, weight: .semibold, alpha: 0.9))
        if !date.isEmpty {
            name.append(text("  ·  \(date)", size: 28, weight: .medium, alpha: 0.65))
        }
        let nameHeight = name.size().height
        name.draw(in: CGRect(x: margin, y: size.height - 64 - nameHeight,
                             width: size.width - margin * 2, height: nameHeight))

        // Title: the biggest size that wraps to three lines or fewer (the
        // smallest truncates). TextKit measures and draws the same layout.
        var heading = TextBlock(text(title, size: 76, weight: .bold, alpha: 1), width: 960)
        for fontSize: CGFloat in [68, 60, 54] where heading.lines > 3 {
            heading = TextBlock(text(title, size: fontSize, weight: .bold, alpha: 1), width: 960)
        }
        heading.balance(minimumWidth: 480)
        heading.limit(lines: 3)

        // Subtitle: a tagline of up to three lines. Its
        // measure follows the title's width (within 680-860) so a short title
        // doesn't sit over a long, thin line, and its lines are balanced too.
        let measure = min(max(heading.width, 680), 860)
        let sub = TextBlock(text(subtitle, size: 38, weight: .medium, alpha: 0.65, leading: 1.25), width: measure)
        sub.balance(minimumWidth: 460)
        sub.limit(lines: 3)

        // Title and subtitle centred vertically as one block.
        let gap: CGFloat = subtitle.isEmpty ? 0 : 12
        let subHeight = subtitle.isEmpty ? 0 : sub.height
        let top = ((size.height - heading.height - gap - subHeight) / 2).rounded()
        heading.draw(at: CGPoint(x: margin, y: top))
        sub.draw(at: CGPoint(x: margin, y: top + heading.height + gap))

        guard let jpeg = rep.representation(using: .jpeg, properties: [.compressionFactor: 0.85]) else {
            throw CocoaError(.fileWriteUnknown)
        }
        return jpeg
    }

    /// A TextKit layout of one attributed string at a fixed width.
    private struct TextBlock {
        private let layout = NSLayoutManager()
        private let container: NSTextContainer
        private let storage: NSTextStorage

        init(_ attributed: NSAttributedString, width: CGFloat) {
            storage = NSTextStorage(attributedString: attributed)
            container = NSTextContainer(size: CGSize(width: width, height: .greatestFiniteMagnitude))
            container.lineFragmentPadding = 0
            layout.addTextContainer(container)
            storage.addLayoutManager(layout)
        }

        var lines: Int {
            var count = 0
            layout.enumerateLineFragments(forGlyphRange: layout.glyphRange(for: container)) { _, _, _, _, _ in count += 1 }
            return count
        }

        var width: CGFloat {
            layout.ensureLayout(for: container)
            return layout.usedRect(for: container).width.rounded(.up)
        }

        var height: CGFloat {
            layout.ensureLayout(for: container)
            return layout.usedRect(for: container).height.rounded(.up)
        }

        /// Narrows the container as far as it goes without adding a line, so
        /// the lines come out even (like CSS `text-wrap: balance`).
        func balance(minimumWidth: CGFloat) {
            let lines = self.lines
            guard lines > 1 else { return }
            // Never narrower than the widest word, or TextKit splits it.
            let text = storage.string as NSString
            var widest: CGFloat = 0
            text.enumerateSubstrings(in: NSRange(location: 0, length: text.length), options: .byWords) { _, range, _, _ in
                widest = max(widest, storage.attributedSubstring(from: range).size().width)
            }
            let floor = max(minimumWidth, widest.rounded(.up) + 2)
            var width = container.size.width
            while width - 10 >= floor {
                container.size.width = width - 10
                if self.lines > lines { break }
                width -= 10
            }
            container.size.width = width
        }

        func limit(lines: Int) {
            container.maximumNumberOfLines = lines
            container.lineBreakMode = .byTruncatingTail
        }

        func draw(at origin: CGPoint) {
            layout.drawGlyphs(forGlyphRange: layout.glyphRange(for: container), at: origin)
        }
    }

    /// White SF Pro text. Line height is fixed so titles wrap evenly; glyphs
    /// SF Pro lacks (Japanese, emoji) fall back to system fonts.
    private static func text(_ string: String, size: CGFloat, weight: NSFont.Weight, alpha: CGFloat,
                             leading: CGFloat = 1.08) -> NSAttributedString {
        let paragraph = NSMutableParagraphStyle()
        paragraph.minimumLineHeight = (size * leading).rounded()
        paragraph.maximumLineHeight = (size * leading).rounded()
        paragraph.lineBreakMode = .byWordWrapping
        return NSAttributedString(string: string, attributes: [
            .font: NSFont.systemFont(ofSize: size, weight: weight),
            .foregroundColor: NSColor(white: 1, alpha: alpha),
            .paragraphStyle: paragraph,
            .kern: -size * 0.01,
        ])
    }

    /// The photo cropped to fill the card, heavily blurred, plus its mean
    /// luminance (0-1). Blurring a small copy and letting the draw scale it up
    /// is fast and looks the same.
    private static func blurred(_ image: CGImage) -> (image: CGImage, luminance: Double)? {
        let small = CGSize(width: 300, height: 158)
        guard let context = CGContext(
            data: nil, width: Int(small.width), height: Int(small.height), bitsPerComponent: 8,
            bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        let scale = max(small.width / CGFloat(image.width), small.height / CGFloat(image.height))
        let drawn = CGSize(width: CGFloat(image.width) * scale, height: CGFloat(image.height) * scale)
        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: (small.width - drawn.width) / 2, y: (small.height - drawn.height) / 2,
                                       width: drawn.width, height: drawn.height))
        guard let fitted = context.makeImage(), let pixels = context.data else { return nil }

        let bytes = pixels.assumingMemoryBound(to: UInt8.self)
        var total = 0.0
        for y in 0..<context.height {
            for x in 0..<context.width {
                let p = y * context.bytesPerRow + x * 4
                total += 0.2126 * Double(bytes[p]) + 0.7152 * Double(bytes[p + 1]) + 0.0722 * Double(bytes[p + 2])
            }
        }
        let luminance = total / Double(context.width * context.height) / 255

        let input = CIImage(cgImage: fitted)
        let output = input.clampedToExtent()
            .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: 6])
            .cropped(to: input.extent)
        guard let result = CIContext().createCGImage(output, from: input.extent) else { return nil }
        return (result, luminance)
    }

    // MARK: - Inputs

    /// The header wordmark, recoloured white.
    private static func wordmark(root: URL) throws -> NSImage {
        let svg = try String(contentsOf: root.appending(path: "Assets/img/site/logo.svg"), encoding: .utf8)
            .replacingOccurrences(of: "<path ", with: "<path fill=\"#fff\" ")
        guard let image = NSImage(data: Data(svg.utf8)) else { throw CocoaError(.fileReadCorruptFile) }
        return image
    }

    /// Front matter as plain strings, split on the first `:` like Ignite.
    private static func frontMatter(_ url: URL) throws -> [String: String] {
        let text = try String(contentsOf: url, encoding: .utf8)
        let parts = text.components(separatedBy: "---")
        guard parts.count >= 3 else { return [:] }
        var meta: [String: String] = [:]
        for line in parts[1].split(separator: "\n") {
            guard let colon = line.firstIndex(of: ":") else { continue }
            let key = line[..<colon].trimmingCharacters(in: .whitespaces)
            meta[key] = line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)
        }
        return meta
    }

    /// `2017-09-19 01:12:24` → `19 September 2017`.
    static func formattedDate(_ value: String) -> String {
        let input = DateFormatter()
        input.locale = Locale(identifier: "en_US_POSIX")
        input.dateFormat = "yyyy-MM-dd"
        guard let date = input.date(from: String(value.prefix(10))) else { return value }
        let output = DateFormatter()
        output.locale = Locale(identifier: "en_AU")
        output.dateFormat = "d MMMM yyyy"
        return output.string(from: date)
    }
}
