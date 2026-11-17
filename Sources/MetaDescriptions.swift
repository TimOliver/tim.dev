// tim.dev - released into the public domain. No rights reserved.

import Foundation
import SwiftSoup

/// Post-publish pass that gives pages a useful search snippet (meta
/// description and og:description), read from the built HTML:
///
/// - Posts: their opening sentences, up to ~155 characters. Ignite's default
///   is the first paragraph alone, which for a chatty opener is just
///   "Hi everyone!!". A post's own `description:` front matter wins.
/// - Other pages still on the site-wide description (Apps, Code, Art, Talks,
///   Archive, Contact, About...): their page tagline instead. The home page
///   keeps the site description.
/// - Collection detail pages: Ignite's first paragraph, cut down the same way
///   as a post's when it runs past the limit.
enum MetaDescriptions {

    /// The snippet length search engines show before truncating.
    static let limit = 155

    static func rewrite(root: URL, siteDescription: String) throws {
        let fm = FileManager.default
        let build = root.appending(path: "Build")

        // Posts that set their own `description:` are left alone.
        var authored = Set<String>()
        let posts = root.appending(path: "Content/posts")
        for name in try fm.contentsOfDirectory(atPath: posts.path) where name.hasSuffix(".md") {
            let meta = try LinkCards.frontMatter(posts.appending(path: name))
            if let path = meta["path"], !(meta["description"] ?? "").isEmpty { authored.insert(path) }
        }

        guard let files = fm.enumerator(at: build, includingPropertiesForKeys: nil) else { return }
        for case let file as URL in files where file.lastPathComponent == "index.html" {
            let path = String(file.deletingLastPathComponent().path.dropFirst(build.path.count)) + "/"
            let section = path.split(separator: "/").first.map(String.init) ?? ""
            if section.isEmpty { continue }  // home keeps the site description
            let isPost = section.count == 4 && section.allSatisfy(\.isNumber)
            if isPost && authored.contains(path) { continue }

            let html = try String(contentsOf: file, encoding: .utf8)
            let doc = try SwiftSoup.parse(html)
            let current = try doc.select("meta[name=description]").attr("content")

            var description = ""
            if isPost {
                // Prose in reading order - paragraphs and list items - skipping
                // image-only paragraphs, embedded social cards, and list items
                // that wrap their own paragraphs (those are read as <p>s).
                let blocks = try doc.select("article > section p, article > section li").array().filter {
                    let insideCard = try $0.parents().array().contains { $0.hasClass("embed_social") }
                    let wrapsParagraphs = try $0.tagName() == "li" && !$0.select("p").isEmpty()
                    return !insideCard && !wrapsParagraphs
                }
                let text = try blocks.map { try $0.text() }.filter { !$0.isEmpty }.joined(separator: " ")
                description = excerpt(text)
            } else if current == siteDescription {
                description = try ["main .page-subtitle", "main .about-tagline"]
                    .lazy.compactMap { try doc.select($0).first()?.text() }
                    .first { !$0.isEmpty } ?? ""
            } else if current.count > limit {
                // Collection detail pages get Ignite's whole first paragraph,
                // which runs to 400+ characters on some Art pieces.
                description = excerpt(current)
            }
            guard !description.isEmpty, description != current else { continue }

            let value = escape(description)
            var out = html
            for pattern in [#"(<meta name="description" content=")[^"]*""#,
                            #"(<meta property="og:description" content=")[^"]*""#] {
                let regex = try NSRegularExpression(pattern: pattern)
                out = regex.stringByReplacingMatches(
                    in: out, range: NSRange(out.startIndex..., in: out),
                    withTemplate: "$1\(NSRegularExpression.escapedTemplate(for: value))\"")
            }
            if out != html { try out.write(to: file, atomically: true, encoding: .utf8) }
        }
    }

    /// Whole sentences from the start of `text`, as many as fit in `limit`
    /// characters. A first sentence that's already too long is cut at a word
    /// boundary with an ellipsis.
    static func excerpt(_ text: String, limit: Int = limit) -> String {
        let clean = text.split(whereSeparator: \.isWhitespace).joined(separator: " ")
        guard clean.count > limit else { return clean }

        // Sentence ends: . ! ? … followed by a space, or Japanese 。！？
        // (which aren't followed by one).
        var sentences: [String] = []
        var current = ""
        let characters = Array(clean)
        for (i, c) in characters.enumerated() {
            current.append(c)
            let next = i + 1 < characters.count ? characters[i + 1] : " "
            let latinEnd = ".!?…".contains(c) && next == " "
            let japaneseEnd = "。！？".contains(c) && !"。！？」』）".contains(next)
            if latinEnd || japaneseEnd {
                sentences.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            }
        }
        if !current.trimmingCharacters(in: .whitespaces).isEmpty {
            sentences.append(current.trimmingCharacters(in: .whitespaces))
        }

        var out = ""
        for sentence in sentences {
            let joiner = out.isEmpty || out.last.map { "。！？".contains($0) } == true ? "" : " "
            let candidate = out + joiner + sentence
            if candidate.count > limit { break }
            out = candidate
        }
        // Enough whole sentences to stand on their own.
        if out.count >= 90 { return out }

        // Otherwise the next sentence is too long to fit whole: fill the rest
        // of the snippet with it, cut at a word boundary, with an ellipsis.
        let start = out.isEmpty ? "" : out + " "
        let rest = String(clean.dropFirst(out.count).drop { $0 == " " })
        let cut = String((start + rest).prefix(limit - 1))
        var trimmed = cut
        if let space = cut.range(of: " ", options: .backwards), cut.distance(from: cut.startIndex, to: space.lowerBound) > start.count {
            trimmed = String(cut[..<space.lowerBound])
        }
        return trimmed.trimmingCharacters(in: CharacterSet(charactersIn: " ,;:-–—")) + "…"
    }

    private static func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
}
