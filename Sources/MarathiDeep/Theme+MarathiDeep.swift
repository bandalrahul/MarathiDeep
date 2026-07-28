import Publish
import Plot

extension Theme where Site == MarathiDeep {
    static var marathiDeep: Self {
        Theme(
            htmlFactory: MarathiDeepHTMLFactory(),
            resourcePaths: ["Resources/MarathiDeepTheme/styles.css"]
        )
    }
}

private struct MarathiDeepHTMLFactory: HTMLFactory {
    func makeIndexHTML(for index: Index,
                       context: PublishingContext<MarathiDeep>) throws -> HTML {
        HTML(
            .lang(context.site.language),
            .head(for: index, on: context.site),
            .body {
                SiteHeader(context: context, selectedSectionID: nil, isHome: true)
                Wrapper {
                    Div {
                        H1(index.title)
                        Paragraph(context.site.description)
                            .class("description")
                    }
                    .class("hero")

                    H2("Latest content")
                    ItemList(
                        items: context.allItems(
                            sortedBy: \.date,
                            order: .descending
                        ),
                        site: context.site
                    )
                }
                SiteFooter(siteName: context.site.name)
            }
        )
    }

    func makeSectionHTML(for section: Section<MarathiDeep>,
                         context: PublishingContext<MarathiDeep>) throws -> HTML {
        HTML(
            .lang(context.site.language),
            .head(for: section, on: context.site),
            .body {
                SiteHeader(context: context, selectedSectionID: section.id, isHome: false)
                Wrapper {
                    H1(section.title)
                    if !section.body.isEmpty {
                        Div(section.body).class("section-intro")
                    }
                    ItemList(items: section.items, site: context.site)
                }
                SiteFooter(siteName: context.site.name)
            }
        )
    }

    func makeItemHTML(for item: Item<MarathiDeep>,
                      context: PublishingContext<MarathiDeep>) throws -> HTML {
        HTML(
            .lang(context.site.language),
            .head(for: item, on: context.site),
            .body(
                .class("item-page"),
                .components {
                    SiteHeader(context: context, selectedSectionID: item.sectionID, isHome: false)
                    Wrapper {
                        Article {
                            Div(item.content.body).class("content")
                            if !item.tags.isEmpty {
                                Div {
                                    Span("Tagged with: ").class("tag-label")
                                    ItemTagList(item: item, site: context.site)
                                }
                                .class("tags-row")
                            }
                        }
                    }
                    SiteFooter(siteName: context.site.name)
                }
            )
        )
    }

    func makePageHTML(for page: Page,
                      context: PublishingContext<MarathiDeep>) throws -> HTML {
        HTML(
            .lang(context.site.language),
            .head(for: page, on: context.site),
            .body {
                SiteHeader(context: context, selectedSectionID: nil, isHome: false)
                Wrapper(page.body)
                SiteFooter(siteName: context.site.name)
            }
        )
    }

    func makeTagListHTML(for page: TagListPage,
                         context: PublishingContext<MarathiDeep>) throws -> HTML? {
        HTML(
            .lang(context.site.language),
            .head(for: page, on: context.site),
            .body {
                SiteHeader(context: context, selectedSectionID: nil, isHome: false)
                Wrapper {
                    H1("Browse all tags")
                    List(page.tags.sorted()) { tag in
                        ListItem {
                            Link(tag.string,
                                 url: context.site.path(for: tag).absoluteString
                            )
                        }
                        .class("tag")
                    }
                    .class("all-tags")
                }
                SiteFooter(siteName: context.site.name)
            }
        )
    }

    func makeTagDetailsHTML(for page: TagDetailsPage,
                            context: PublishingContext<MarathiDeep>) throws -> HTML? {
        HTML(
            .lang(context.site.language),
            .head(for: page, on: context.site),
            .body {
                SiteHeader(context: context, selectedSectionID: nil, isHome: false)
                Wrapper {
                    H1 {
                        Text("Tagged with ")
                        Span(page.tag.string).class("tag")
                    }

                    Link("Browse all tags",
                        url: context.site.tagListPath.absoluteString
                    )
                    .class("browse-all")

                    ItemList(
                        items: context.items(
                            taggedWith: page.tag,
                            sortedBy: \.date,
                            order: .descending
                        ),
                        site: context.site
                    )
                }
                SiteFooter(siteName: context.site.name)
            }
        )
    }
}

private struct Wrapper: ComponentContainer {
    @ComponentBuilder var content: ContentProvider

    var body: Component {
        Div(content: content).class("wrapper")
    }
}

private struct SiteHeader: Component {
    var context: PublishingContext<MarathiDeep>
    var selectedSectionID: MarathiDeep.SectionID?
    var isHome: Bool

    private static let sectionTitles: [MarathiDeep.SectionID: String] = [
        .ai: "AI",
        .technology: "Technology",
        .health: "Health",
        .finance: "Finance",
        .fitness: "Fitness",
        .education: "Education",
        .about: "About"
    ]

    var body: Component {
        Header {
            Div {
                Link(context.site.name, url: "/")
                    .class("site-name")
                navigation
            }
            .class("wrapper header-inner")
        }
    }

    private var navigation: Component {
        Navigation {
            List(navItems) { item in
                Link(item.title, url: item.url)
                    .class(item.isSelected ? "selected" : "")
            }
        }
        .class("site-nav")
    }

    private var navItems: [(title: String, url: String, isSelected: Bool)] {
        var items: [(title: String, url: String, isSelected: Bool)] = [
            ("Home", "/", isHome)
        ]

        for sectionID in MarathiDeep.SectionID.allCases {
            let section = context.sections[sectionID]
            let title = Self.sectionTitles[sectionID] ?? section.title
            items.append((
                title,
                section.path.absoluteString,
                sectionID == selectedSectionID
            ))
        }

        return items
    }
}

private struct ItemList: Component {
    var items: [Item<MarathiDeep>]
    var site: MarathiDeep

    var body: Component {
        if items.isEmpty {
            Paragraph("No articles yet. Check back soon.")
                .class("empty-state")
        } else {
            List(items) { item in
                Article {
                    H1(Link(item.title, url: item.path.absoluteString))
                    ItemTagList(item: item, site: site)
                    Paragraph(item.description)
                }
            }
            .class("item-list")
        }
    }
}

private struct ItemTagList: Component {
    var item: Item<MarathiDeep>
    var site: MarathiDeep

    var body: Component {
        List(item.tags) { tag in
            Link(tag.string, url: site.path(for: tag).absoluteString)
        }
        .class("tag-list")
    }
}

private struct SiteFooter: Component {
    var siteName: String

    var body: Component {
        Footer {
            Div {
                Paragraph("© \(siteName). Knowledge shared in Marathi.")
                Paragraph {
                    Text("Built with ")
                    Link("Publish", url: "https://github.com/johnsundell/publish")
                    Text(" · ")
                    Link("RSS", url: "/feed.rss")
                }
            }
            .class("wrapper")
        }
    }
}
