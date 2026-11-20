// tim.dev - released into the public domain. No rights reserved.

import Foundation
import Ignite

/// Small scripts that must run before first paint, inlined into `<head>` so
/// they cost no render-blocking request. The readable, commented source stays
/// in Assets/js; the page gets it without comments or indentation.
enum InlineScript {

    /// Assets/js/theme.js: sets the theme attributes before first paint.
    static let theme = compact(contentsOf: "Assets/js/theme.js")

    /// Reads a script from the package and strips what the browser doesn't
    /// need. Deliberately simple, not a minifier: it drops whole-line `//`
    /// comments, indentation and blank lines, and keeps every line break so
    /// semicolon insertion behaves exactly as in the source. Comments at the
    /// end of a code line are kept (a `//` could be inside a string).
    static func compact(contentsOf path: String) -> String {
        let url = IgniteWebsite.packageRoot.appending(path: path)
        guard let source = try? String(contentsOf: url, encoding: .utf8) else {
            fatalError("InlineScript: can't read \(path)")
        }
        let code = source
            .split(separator: "\n", omittingEmptySubsequences: true)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("//") }
            .joined(separator: "\n")
        // "</script" inside the code would end the inline <script> early.
        precondition(!code.lowercased().contains("</script"), "InlineScript: \(path) contains </script")
        return code
    }
}
