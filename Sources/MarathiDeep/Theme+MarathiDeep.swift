import Foundation
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
            siteHead(for: index, on: context.site),
            .body {
                SiteHeader(context: context, selectedSectionID: nil, isHome: true)
                Wrapper {
                    Div {
                        H1(index.title)
                        Paragraph(context.site.description)
                            .class("description")
                    }
                    .class("hero")

                    H2("Latest articles")
                    ItemList(
                        items: context.allItems(
                            sortedBy: \.date,
                            order: .descending
                        ),
                        site: context.site
                    )

                    Div {
                        H2("Explore topics")
                        Paragraph("AI, Technology, Health, Finance, Fitness, Education, Travel आणि Schemes — स्पष्ट मराठीत.")
                        List(MarathiDeep.SectionID.allCases.filter { $0 != .about }) { sectionID in
                            let section = context.sections[sectionID]
                            let title = SiteHeader.sectionTitles[sectionID] ?? section.title
                            return Link(title, url: section.path.absoluteString)
                        }
                        .class("topic-links")
                    }
                    .class("topics-block")
                }
                SiteFooter(siteName: context.site.name)
                CookieNotice()
            }
        )
    }

    func makeSectionHTML(for section: Section<MarathiDeep>,
                         context: PublishingContext<MarathiDeep>) throws -> HTML {
        HTML(
            .lang(context.site.language),
            siteHead(for: section, on: context.site),
            .body {
                SiteHeader(context: context, selectedSectionID: section.id, isHome: false)
                Wrapper {
                    H1(section.title)
                    if !section.body.isEmpty {
                        Div(section.body).class("section-intro content")
                    }
                    if needsDisclaimer(section.id) {
                        DisclaimerBanner(sectionID: section.id)
                    }
                    ItemList(items: section.items, site: context.site)
                }
                SiteFooter(siteName: context.site.name)
                CookieNotice()
            }
        )
    }

    func makeItemHTML(for item: Item<MarathiDeep>,
                      context: PublishingContext<MarathiDeep>) throws -> HTML {
        HTML(
            .lang(context.site.language),
            siteHead(for: item, on: context.site),
            .body(
                .class("item-page"),
                .components {
                    SiteHeader(context: context, selectedSectionID: item.sectionID, isHome: false)
                    Wrapper {
                        Article {
                            if needsDisclaimer(item.sectionID) {
                                DisclaimerBanner(sectionID: item.sectionID)
                            }
                            Div(item.content.body).class("content")
                            Div {
                                Paragraph("लेखक / संपादन: मराठीदीप संपादकीय टीम")
                                    .class("byline")
                                Paragraph {
                                    Text("अभिप्राय किंवा दुरुस्ती: ")
                                    Link(SiteConfig.contactEmail,
                                         url: "mailto:\(SiteConfig.contactEmail)")
                                }
                                .class("byline")
                            }
                            .class("article-meta")
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
                    CookieNotice()
                }
            )
        )
    }

    func makePageHTML(for page: Page,
                      context: PublishingContext<MarathiDeep>) throws -> HTML {
        HTML(
            .lang(context.site.language),
            siteHead(for: page, on: context.site),
            .body {
                SiteHeader(context: context, selectedSectionID: nil, isHome: false)
                Wrapper {
                    Article {
                        Div(page.body).class("content legal-page")
                    }
                }
                SiteFooter(siteName: context.site.name)
                CookieNotice()
            }
        )
    }

    func makeTagListHTML(for page: TagListPage,
                         context: PublishingContext<MarathiDeep>) throws -> HTML? {
        HTML(
            .lang(context.site.language),
            siteHead(for: page, on: context.site),
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
                CookieNotice()
            }
        )
    }

    func makeTagDetailsHTML(for page: TagDetailsPage,
                            context: PublishingContext<MarathiDeep>) throws -> HTML? {
        HTML(
            .lang(context.site.language),
            siteHead(for: page, on: context.site),
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
                CookieNotice()
            }
        )
    }
}

private func needsDisclaimer(_ sectionID: MarathiDeep.SectionID) -> Bool {
    sectionID == .health || sectionID == .finance || sectionID == .fitness || sectionID == .schemes
}

private func siteHead<T: Location>(for location: T, on site: MarathiDeep) -> Node<HTML.DocumentContext> {
    let adsense = SiteConfig.adsenseClientID.trimmingCharacters(in: .whitespacesAndNewlines)
    let verification = SiteConfig.googleSiteVerification.trimmingCharacters(in: .whitespacesAndNewlines)

    return .head(
        .encoding(.utf8),
        .siteName(site.name),
        .url(site.url(for: location)),
        .title(location.title.isEmpty ? site.name : "\(location.title) | \(site.name)"),
        .description(location.description.isEmpty ? site.description : location.description),
        .twitterCardType(location.imagePath == nil ? .summary : .summaryLargeImage),
        .stylesheet("/styles.css"),
        .viewport(.accordingToDevice),
        .unwrap(site.favicon) { .favicon($0) },
        .rssFeedLink("/feed.rss", title: "Subscribe to \(site.name)"),
        .unwrap(location.imagePath ?? site.imagePath) { path in
            .socialImageLink(site.url(for: path))
        },
        .meta(.name("author"), .content("मराठीदीप संपादकीय टीम")),
        .meta(.name("robots"), .content("index,follow")),
        .if(!verification.isEmpty, .meta(.name("google-site-verification"), .content(verification))),
        .if(!adsense.isEmpty,
            .script(
                .async(),
                .src("https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=\(adsense)"),
                .attribute(named: "crossorigin", value: "anonymous")
            )
        )
    )
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

    static let sectionTitles: [MarathiDeep.SectionID: String] = [
        .ai: "AI",
        .technology: "Technology",
        .health: "Health",
        .finance: "Finance",
        .fitness: "Fitness",
        .education: "Education",
        .travel: "Travel",
        .schemes: "Schemes",
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
            Div {
                Paragraph("या विभागात लवकरच सविस्तर लेख प्रकाशित होतील. तोपर्यंत Home वरील नवीनतम लेख किंवा इतर विषय पाहा.")
                Paragraph {
                    Link("Home वर जा", url: "/")
                    Text(" · ")
                    Link("Contact", url: "/contact")
                }
            }
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

private struct DisclaimerBanner: Component {
    var sectionID: MarathiDeep.SectionID

    var body: Component {
        let text: String
        switch sectionID {
        case .health, .fitness:
            text = "सूचना: हे सामान्य माहिती लेख आहेत, वैद्यकीय सल्ला नाही. वैयक्तिक आरोग्य निर्णयापूर्वी पात्र डॉक्टरांचा सल्ला घ्या."
        case .finance:
            text = "सूचना: हे शैक्षणिक लेख आहेत, वैयक्तिक आर्थिक/गुंतवणूक सल्ला नाही. निर्णय घेण्यापूर्वी पात्र सल्लागाराचा सल्ला घ्या."
        case .schemes:
            text = "सूचना: शासकीय योजनांची माहिती सामान्य मार्गदर्शनासाठी आहे. अटी, पात्रता आणि अर्ज प्रक्रिया बदलू शकते — अधिकृत सरकारी संकेतस्थळावर पडताळा."
        default:
            text = ""
        }

        return Div {
            Paragraph(text)
            Paragraph {
                Link("Terms & Disclaimer वाचा", url: "/terms")
            }
        }
        .class("disclaimer-banner")
    }
}

private struct CookieNotice: Component {
    var body: Component {
        Div {
            Paragraph {
                Text("ही साईट अनुभव सुधारण्यासाठी आणि (लागू असल्यास) जाहिरातींसाठी कुकीज वापरू शकते. तपशील: ")
                Link("Privacy Policy", url: "/privacy-policy")
                Text(". ")
            }
            Node<HTML.BodyContext>.element(named: "button", nodes: [
                .attribute(named: "type", value: "button"),
                .attribute(
                    named: "onclick",
                    value: "document.getElementById('cookie-notice').style.display='none';try{localStorage.setItem('md_cookie_ok','1')}catch(e){}"
                ),
                .text("समजले")
            ])
            Node<HTML.BodyContext>.script(
                .raw(
                    """
                    try{if(localStorage.getItem('md_cookie_ok')==='1'){var n=document.getElementById('cookie-notice');if(n)n.style.display='none';}}catch(e){}
                    """
                )
            )
        }
        .id("cookie-notice")
        .class("cookie-notice")
    }
}

private struct SiteFooter: Component {
    var siteName: String

    var body: Component {
        Footer {
            Div {
                Div {
                    Paragraph(siteName).class("footer-brand")
                    Paragraph("ज्ञान, तंत्रज्ञान आणि जीवनशैली — मराठीतून.")
                    Paragraph {
                        Text("संपर्क: ")
                        Link(SiteConfig.contactEmail, url: "mailto:\(SiteConfig.contactEmail)")
                    }
                }
                .class("footer-about")

                Navigation {
                    List {
                        ListItem { Link("About", url: "/about") }
                        ListItem { Link("Contact", url: "/contact") }
                        ListItem { Link("Privacy Policy", url: "/privacy-policy") }
                        ListItem { Link("Terms & Disclaimer", url: "/terms") }
                        ListItem { Link("RSS", url: "/feed.rss") }
                    }
                }
                .class("footer-nav")
            }
            .class("wrapper footer-inner")

            Paragraph("© \(Calendar.current.component(.year, from: Date())) \(siteName). All rights reserved.")
                .class("footer-copy wrapper")
        }
    }
}
