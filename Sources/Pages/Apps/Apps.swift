// tim.dev - released into the public domain. No rights reserved.

import Foundation
import Ignite

/// The `/apps/` grid index. Reads the `apps` content collection and renders a
/// 2-up card grid. Uses the Include-string pattern (see `AppRenderer`).
struct Apps: StaticPage {

    /// Page title - Ignite renders it into the `<title>` tag and uses it as the
    /// nav/heading label. A constant here, since this is the fixed apps index.
    var title = "Apps"

    /// Injected article loader (the `\.articles` environment value). Read in
    /// `body` to pull the `apps` content collection.
    @Environment(\.articles) private var articles

    /// Builds the grid include for `/apps/`. Loads the collection, parses each
    /// article's front matter, renders the card grid, and returns the matching
    /// `Include` (the Include-string pattern - markup is written to a file on
    /// disk and referenced by name; see `CollectionRenderer.include`).
    var body: some HTML {

        // Every article filed under the `apps` collection, newest first, each
        // parsed into the `AppInfo` front-matter view the renderer consumes.
        let apps = articles.typed("apps")
            .sorted { $0.date > $1.date }
            .map(AppInfo.init)

        // Assemble the whole grid as one HTML string.
        let html = AppRenderer.gridHTML(for: apps)

        // Write that markup to Includes/_apps/index.html and return the
        // `Include` that points Ignite at it.
        return CollectionRenderer.include(key: "index", dir: "apps", html: html)
    }
}

/// Grid-index markup for `AppRenderer` (the enum itself and the shared
/// `iconTile`/`badges`/`stage` builders live in AppModel.swift).
extension AppRenderer {

    /// Renders the full `/apps/` grid: page title, subtitle, then one linked
    /// card per app (an icon + name/tagline/badges head, with the screenshot
    /// stage below). Returns the assembled HTML string that `Apps.body` writes
    /// to its include.
    static func gridHTML(for apps: [AppInfo]) -> String {

        // Open the collection wrapper, lay down the page heading and intro
        // blurb, then open the grid the cards drop into.
        var s = #"<div class="collection">"#
        s += #"<h1 class="page-title">Apps</h1>"#
        s += #"<p class="page-subtitle">I've been crafting software for over two decades. Here are some of the apps I've helped bring to life.</p>"#
        s += #"<div class="collection-grid">"#

        for app in apps {

            // The whole card is one link through to the app's detail page;
            // `app.path` is escaped as it lands in the href attribute.
            s += #"<a class="collection-card" href="\#(escape(app.path))">"#

            // Head row: the icon tile beside the name/tagline/badges column.
            // `sizes: "64px"` matches the grid card's fixed 64px `.app-icon`
            // (see apps.css), so the browser fetches the right candidate.
            s += #"<div class="app-card-head">"#
            s += iconTile(icon: app.icon, sizes: "64px")
            s += #"<div class="app-card-meta">"#
            s += #"<h2 class="app-card-name">\#(escape(app.title))</h2>"#
            s += #"<p class="app-card-tagline">\#(escape(app.tagline))</p>"#
            s += #"<div class="app-badges">\#(badges(year: app.year, platform: app.platform))</div>"#
            s += "</div>"  // app-card-meta
            s += "</div>"  // app-card-head

            // Screenshot stage under the head. The shots render bare (their
            // device chrome is baked into each PNG), and an app with none yet
            // gets the flat empty stage - both handled inside `stage`.
            s += stage(
                app.shots,
                className: "app-stage",
                sizes: "(max-width: 720px) 90vw, 240px",
                appName: app.title
            )

            s += "</a>"
        }

        // Close the grid and the collection wrapper, then hand back the string.
        s += "</div>"  // collection-grid
        s += "</div>"  // collection
        return s
    }
}
