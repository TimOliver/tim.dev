import Foundation
import Ignite

@main
struct IgniteWebsite {
    static func main() async {
        var site = TimDevSite()

        do {
            try await site.publish()
        } catch {
            print(error.localizedDescription)
        }
    }
}

struct TimDevSite: Site {
    var name = "[tim.dev]"
    var url = URL(static: "https://tim.dev")
    var useDefaultBootstrapURLs = BootstrapOptions.none
    var builtInIconsEnabled = BootstrapOptions.none

    var author = "Tim Oliver"

    var homePage = Home()
    var layout = MainLayout()
}
