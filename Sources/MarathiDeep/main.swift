import Foundation
import Publish
import Plot

/// Fill these in before applying for / enabling Google AdSense.
enum SiteConfig {
    /// Example: "ca-pub-1234567890123456" — leave empty until AdSense gives you an ID.
    static let adsenseClientID = ""

    /// Public contact used on Contact / Privacy pages and footer.
    static let contactEmail = "bandalrahul@yahoo.com"

    /// Optional Google Search Console HTML tag content value.
    static let googleSiteVerification = ""
}

/// Configuration for the मराठीदीप website.
struct MarathiDeep: Website {
    enum SectionID: String, WebsiteSectionID {
        case ai
        case technology
        case health
        case finance
        case fitness
        case education
        case travel
        case schemes
        case about
    }

    struct ItemMetadata: WebsiteItemMetadata {}

    var url = URL(string: "https://marathideep.com")!
    var name = "मराठीदीप"
    var description = "ज्ञान, तंत्रज्ञान आणि जीवनशैली — मराठीतून, सोप्या भाषेत. AI, Technology, Health, Finance, Fitness, Education, Travel आणि Government Schemes विषयांवरील उपयुक्त मराठी लेख."
    var language: Language { .marathi }
    var imagePath: Path? { nil }
    var favicon: Favicon? { nil }
}

try MarathiDeep().publish(
    withTheme: .marathiDeep,
    // Publish's RSS generator can segfault on Linux CI (DateFormatter concurrency).
    // Keep RSS on macOS/local builds; skip it on Linux runners.
    rssFeedConfig: {
        #if os(Linux)
        return nil
        #else
        return .default
        #endif
    }(),
    additionalSteps: [
        .step(named: "Write ads.txt when AdSense ID is configured") { context in
            let client = SiteConfig.adsenseClientID.trimmingCharacters(in: .whitespacesAndNewlines)
            guard client.hasPrefix("ca-pub-") else { return }

            let publisher = client.replacingOccurrences(of: "ca-", with: "")
            let body = "google.com, \(publisher), DIRECT, f08c47fec0942fa0\n"
            let file = try context.createOutputFile(at: "ads.txt")
            try file.write(body)
        }
    ]
)
