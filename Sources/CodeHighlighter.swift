// tim.dev - released into the public domain. No rights reserved.

import Foundation

/// Build-time syntax highlighting for the C-family code in posts (the migrated
/// Objective-C and C gists). One left-to-right pass wraps each token in a
/// `<span class="hl-…">`; site.css colours them with Xcode's default light and
/// dark palettes. No JavaScript, and unknown languages pass through as plain
/// escaped text.
enum CodeHighlighter {

    /// Fenced-code language names this highlighter understands.
    static func supports(_ language: String) -> Bool {
        ["objc", "objective-c", "objectivec", "c", "h", "m"].contains(language.lowercased())
    }

    private static let keywords: Set<String> = [
        "auto", "break", "case", "char", "const", "continue", "default", "do", "double", "else",
        "enum", "extern", "float", "for", "goto", "if", "inline", "int", "long", "register",
        "return", "short", "signed", "sizeof", "static", "struct", "switch", "typedef", "union",
        "unsigned", "void", "volatile", "while",
        "id", "self", "super", "nil", "Nil", "YES", "NO", "NULL", "BOOL", "SEL", "Class",
        "instancetype", "nonatomic", "atomic", "strong", "weak", "assign", "copy", "readonly",
        "readwrite", "nullable", "nonnull", "__block", "__weak", "__strong", "IBAction", "IBOutlet",
    ]

    /// Escapes text for HTML.
    private static func escape(_ s: Substring) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    private static func span(_ cls: String, _ text: Substring) -> String {
        #"<span class="hl-\#(cls)">\#(escape(text))</span>"#
    }

    /// Returns the code as highlighted HTML (already escaped).
    static func highlight(_ code: String) -> String {
        let chars = Array(code.unicodeScalars)
        var out = ""
        var i = chars.startIndex
        var lineStart = true

        func sub(_ a: Int, _ b: Int) -> Substring {
            Substring(String(String.UnicodeScalarView(chars[a..<b])))
        }
        func isIdentStart(_ c: Unicode.Scalar) -> Bool { c == "_" || c.properties.isAlphabetic }
        func isIdent(_ c: Unicode.Scalar) -> Bool { isIdentStart(c) || ("0"..."9").contains(c) }

        while i < chars.count {
            let c = chars[i]
            let next: Unicode.Scalar? = i + 1 < chars.count ? chars[i + 1] : nil

            // Preprocessor directive: a line whose first non-space is '#'.
            if lineStart && c == "#" {
                var j = i
                while j < chars.count && chars[j] != "\n" { j += 1 }
                out += span("pre", sub(i, j)); i = j; continue
            }
            if c == "\n" { lineStart = true; out += "\n"; i += 1; continue }
            if c == " " || c == "\t" { out += String(c); i += 1; continue }
            lineStart = false

            // Comments.
            if c == "/" && next == "/" {
                var j = i
                while j < chars.count && chars[j] != "\n" { j += 1 }
                out += span("comment", sub(i, j)); i = j; continue
            }
            if c == "/" && next == "*" {
                var j = i + 2
                while j + 1 < chars.count && !(chars[j] == "*" && chars[j + 1] == "/") { j += 1 }
                j = min(j + 2, chars.count)
                out += span("comment", sub(i, j)); i = j; continue
            }

            // Strings (C and @"…") and character literals.
            if c == "\"" || c == "'" || (c == "@" && next == "\"") {
                let quote: Unicode.Scalar = c == "@" ? "\"" : c
                var j = c == "@" ? i + 2 : i + 1
                while j < chars.count && chars[j] != quote && chars[j] != "\n" {
                    j += chars[j] == "\\" ? 2 : 1
                }
                j = min(j + 1, chars.count)
                out += span("string", sub(i, j)); i = j; continue
            }

            // @directives (@interface, @property, @selector…) and @YES/@NO.
            if c == "@", let n = next, isIdentStart(n) {
                var j = i + 1
                while j < chars.count && isIdent(chars[j]) { j += 1 }
                out += span("keyword", sub(i, j)); i = j; continue
            }

            // Numbers, including 1.0f, 0x1F and .5.
            if ("0"..."9").contains(c) || (c == "." && next.map { ("0"..."9").contains($0) } == true) {
                var j = i
                while j < chars.count && (isIdent(chars[j]) || chars[j] == ".") { j += 1 }
                out += span("number", sub(i, j)); i = j; continue
            }

            // Identifiers: keywords, Cocoa/CoreGraphics types, or plain names.
            if isIdentStart(c) {
                var j = i
                while j < chars.count && isIdent(chars[j]) { j += 1 }
                let word = sub(i, j)
                if keywords.contains(String(word)) {
                    out += span("keyword", word)
                } else if word.first?.isUppercase == true, word.count > 2,
                          ["CG", "UI", "NS", "CA", "CF", "TO"].contains(String(word.prefix(2))) {
                    out += span("type", word)
                } else {
                    out += escape(word)
                }
                i = j; continue
            }

            out += escape(sub(i, i + 1)); i += 1
        }
        return out
    }
}
