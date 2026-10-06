// tim.dev - released into the public domain. No rights reserved.

import Foundation
import Ignite
import Markdown

/// The Markdown renderer for everything under `Content/`.
///
/// A port of Ignite's stock `MarkdownToHTML` (same markup, element for
/// element) with two deliberate differences:
///
/// - **Text is escaped.** Ignite emits text, inline code, code blocks and
///   link/image attributes verbatim, so an escaped `&lt;name omitted&gt;` in a
///   post was decoded by the parser and shipped as a real `<name omitted>`
///   tag (its words vanished), a bare `&` went out unescaped, and `<` inside a
///   fenced code block broke the page. Raw HTML blocks and inline HTML still
///   pass through untouched - migrated posts rely on them.
/// - **Every heading is kept.** Ignite is asked to strip "the title" from each
///   article body and implements that as *drop the first heading of any
///   level*. Every post here carries its title in front matter, so the first
///   heading in a body is always a real section heading, and Ignite was
///   silently deleting it from 18 posts. The first heading is still recorded
///   as `title`, which Ignite uses as a fallback when front matter has none.
struct ArticleMarkdownRenderer: ArticleRenderer, MarkupVisitor {

    var title = ""
    var description = ""
    var body = ""

    /// Always `false`: see the type comment. Ignite passes `true` for content
    /// articles; that request is deliberately not honoured.
    let removeTitleFromBody = false

    init(markdown: String, removeTitleFromBody: Bool) throws {
        body = visit(Markdown.Document(parsing: markdown))
    }

    // MARK: - Escaping

    /// Escapes text content for HTML.
    private static func text(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    /// Escapes a double-quoted attribute value.
    private static func attribute(_ s: String) -> String {
        text(s).replacingOccurrences(of: "\"", with: "&quot;")
    }

    /// True when a paragraph sits in a list item, where it renders bare.
    private func isInsideList(_ markup: Markdown.Markup) -> Bool {
        var parent = markup.parent
        while let node = parent {
            if node is Markdown.ListItem { return true }
            parent = node.parent
        }
        return false
    }

    /// Visits every child and concatenates the output.
    private mutating func children(of markup: Markdown.Markup) -> String {
        markup.children.reduce(into: "") { $0 += visit($1) }
    }

    // MARK: - Visitor

    mutating func defaultVisit(_ markup: Markdown.Markup) -> String {
        children(of: markup)
    }

    mutating func visitText(_ text: Markdown.Text) -> String {
        Self.text(text.plainText)
    }

    mutating func visitInlineCode(_ inlineCode: Markdown.InlineCode) -> String {
        "<code>\(Self.text(inlineCode.code))</code>"
    }

    mutating func visitCodeBlock(_ codeBlock: Markdown.CodeBlock) -> String {
        // C-family fences get build-time syntax colouring (CodeHighlighter).
        let code = codeBlock.language.map(CodeHighlighter.supports) == true
            ? CodeHighlighter.highlight(codeBlock.code)
            : Self.text(codeBlock.code)
        if let language = codeBlock.language {
            return #"<pre><code class="language-\#(Self.attribute(language.lowercased()))">\#(code)</code></pre>"#
        }
        return "<pre><code>\(code)</code></pre>"
    }

    mutating func visitHTMLBlock(_ html: Markdown.HTMLBlock) -> String {
        html.rawHTML
    }

    mutating func visitInlineHTML(_ inlineHTML: Markdown.InlineHTML) -> String {
        inlineHTML.rawHTML
    }

    mutating func visitHeading(_ heading: Markdown.Heading) -> String {
        let content = children(of: heading)
        if title.isEmpty { title = content }
        return "<h\(heading.level)>\(content)</h\(heading.level)>"
    }

    mutating func visitParagraph(_ paragraph: Markdown.Paragraph) -> String {
        let content = children(of: paragraph)
        // The first paragraph doubles as the article's description.
        if description.isEmpty { description = content }
        return isInsideList(paragraph) ? content : "<p>\(content)</p>"
    }

    mutating func visitImage(_ image: Markdown.Image) -> String {
        guard let source = image.source else { return "" }
        return #"<img src="\#(Self.attribute(source))" alt="\#(Self.attribute(image.plainText))" class="img-fluid">"#
    }

    mutating func visitLink(_ link: Markdown.Link) -> String {
        #"<a href="\#(Self.attribute(link.destination ?? "#"))">\#(children(of: link))</a>"#
    }

    mutating func visitBlockQuote(_ blockQuote: Markdown.BlockQuote) -> String {
        "<blockquote>\(children(of: blockQuote))</blockquote>"
    }

    mutating func visitEmphasis(_ emphasis: Markdown.Emphasis) -> String {
        "<em>\(children(of: emphasis))</em>"
    }

    mutating func visitStrong(_ strong: Markdown.Strong) -> String {
        "<strong>\(children(of: strong))</strong>"
    }

    mutating func visitStrikethrough(_ strikethrough: Markdown.Strikethrough) -> String {
        "<s>\(children(of: strikethrough))</s>"
    }

    mutating func visitListItem(_ listItem: Markdown.ListItem) -> String {
        "<li>\(children(of: listItem))</li>"
    }

    mutating func visitOrderedList(_ orderedList: Markdown.OrderedList) -> String {
        "<ol>\(children(of: orderedList))</ol>"
    }

    mutating func visitUnorderedList(_ unorderedList: Markdown.UnorderedList) -> String {
        "<ul>\(children(of: unorderedList))</ul>"
    }

    mutating func visitSoftBreak(_ softBreak: Markdown.SoftBreak) -> String {
        " "
    }

    mutating func visitLineBreak(_ lineBreak: Markdown.LineBreak) -> String {
        "<br />"
    }

    mutating func visitThematicBreak(_ thematicBreak: Markdown.ThematicBreak) -> String {
        "<hr />"
    }

    mutating func visitTable(_ table: Markdown.Table) -> String {
        var s = #"<table class="table">"#
        if table.head.childCount > 0 { s += "<thead>\(visit(table.head))</thead>" }
        if table.body.childCount > 0 { s += "<tbody>\(visit(table.body))</tbody>" }
        return s + "</table>"
    }

    mutating func visitTableHead(_ tableHead: Markdown.Table.Head) -> String {
        tableHead.children.reduce(into: "") { $0 += #"<th scope="col">\#(visit($1))</th>"# }
    }

    mutating func visitTableRow(_ tableRow: Markdown.Table.Row) -> String {
        "<tr>" + tableRow.children.reduce(into: "") { $0 += "<td>\(visit($1))</td>" } + "</tr>"
    }
}
