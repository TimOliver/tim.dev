// tim.dev - released into the public domain. No rights reserved.

import Foundation
import SwiftSoup

/// Adds responsive delivery to post images without changing their original
/// lightbox targets. Native loading/srcset also work when JavaScript is off.
@MainActor
enum ArticleImages {
    static func hero(_ path: String, eager: Bool) -> String {
        guard let entry = metadata(for: path) else {
            return #"<img class="hero" src="\#(escape(path))" alt="" loading="\#(eager ? "eager" : "lazy")">"#
        }
        return #"<img class="hero" src="\#(escape(path))" srcset="\#(escape(entry.srcset))" sizes="\#(sizes(maxWidth: 840))" width="\#(entry.width)" height="\#(entry.height)" alt="" loading="\#(eager ? "eager" : "lazy")" decoding="async"\#(eager ? #" fetchpriority="high""# : "")>"#
    }

    /// Normalize every image node, including images sharing paragraphs with
    /// text. Existing links keep their destinations; local media and standalone
    /// external photos get lightbox anchors, while inline external icons do not.
    static func enhance(_ html: String) -> String {
        guard html.contains("<img") else { return html }
        do {
            let parser = Parser.htmlParser().settings(ParseSettings.preserveCase)
            let document = try SwiftSoup.parse("<body>" + html + "</body>", "", parser)
            document.outputSettings().prettyPrint(pretty: false)
            guard let body = document.body() else { return html }

            for image in try body.select("img").array() {
                let ancestors = image.parents().array()
                if ancestors.contains(where: { ["noscript", "template"].contains($0.tagName()) }) {
                    continue
                }
                let source = try image.attr("src")
                guard !source.isEmpty, !source.hasPrefix("data:") else { continue }
                try image.attr("loading", "lazy")
                try image.attr("decoding", "async")

                let entry = metadata(for: source)
                if let entry {
                    try image.attr("width", String(entry.width))
                    try image.attr("height", String(entry.height))
                    try image.attr("srcset", entry.srcset)
                    try image.addClass("post-image")
                    let ratio = Double(entry.width) / Double(entry.height)
                    let width = min(entry.width, Int((650 * ratio).rounded(.down)))
                    let landscapeWidth = min(entry.width, Int((320 * ratio).rounded(.down)))
                    let style = try image.attr("style")
                    try image.attr("style", style + ";--image-width:\(width)px;--image-landscape-width:\(landscapeWidth)px")

                    if let gallery = ancestors.first(where: { $0.hasClass("post-gallery") }) {
                        let columns = try gallery.attr("style").contains("--gallery-cols: 2") ? 2 : 3
                        try image.attr("sizes", sizes(maxWidth: 740, columns: columns))
                    } else {
                        let portrait = sizes(maxWidth: min(740, width))
                        let landscape = "(orientation: landscape) and (max-height: 500px) min(calc(100vw - 40px), \(min(740, landscapeWidth))px), "
                        try image.attr("sizes", landscape + portrait)
                    }
                }

                if ancestors.contains(where: { $0.tagName() == "a" }) { continue }
                let figure = ancestors.first(where: { $0.tagName() == "figure" })
                let paragraph = ancestors.first(where: { $0.tagName() == "p" })
                let isStandalone = try paragraph.map { try $0.text().isEmpty } ?? false
                guard entry != nil || figure != nil || isStandalone else { continue }
                var caption = try image.attr("alt")
                if let figure,
                   let text = try figure.select("figcaption").first()?.text(), !text.isEmpty {
                    caption = text
                }
                try image.wrap(#"<a href="\#(escape(source))" data-lightbox data-caption="\#(escape(caption))"></a>"#)
            }
            return try body.html()
        } catch {
            fatalError("Could not normalize article images: \(error)")
        }
    }

    private static func metadata(for source: String) -> MediaEntry? {
        // URL parsing decodes percent-escaped filenames before manifest lookup.
        guard let url = URL(string: source), url.scheme == nil, source.hasPrefix("/") else { return nil }
        let path = url.path
        if let entry = Media.manifest[path] { return entry }
        if path.hasPrefix("/img/posts/") {
            fatalError("Missing media metadata for \(path). Run python3 Scripts/build-media.py before building.")
        }
        return nil
    }

    /// Match the article/container gutters and the 740px text / 840px hero
    /// measures. Gallery candidates reflect their individual column widths.
    private static func sizes(maxWidth: Int, columns: Int = 1) -> String {
        let gap = (columns - 1) * 10
        func value(_ gutter: Int) -> String {
            "min(calc((100vw - \(gutter + gap)px) / \(columns)), \((maxWidth - gap) / columns)px)"
        }
        return "(max-width: 374.98px) \(value(16)), (max-width: 519.98px) \(value(32)), (max-width: 720px) \(value(40)), \(value(70))"
    }
}
