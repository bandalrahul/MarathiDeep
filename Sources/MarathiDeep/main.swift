import Foundation
import Publish
import Plot

/// Configuration for the मराठीदीप website.
struct MarathiDeep: Website {
    enum SectionID: String, WebsiteSectionID {
        case ai
        case technology
        case health
        case finance
        case fitness
        case education
        case about
    }

    struct ItemMetadata: WebsiteItemMetadata {}

    var url = URL(string: "https://marathideep.com")!
    var name = "मराठीदीप"
    var description = "ज्ञान, तंत्रज्ञान आणि जीवनशैली — मराठीतून, सोप्या भाषेत."
    var language: Language { .marathi }
    var imagePath: Path? { nil }
    var favicon: Favicon? { nil }
}

try MarathiDeep().publish(withTheme: .marathiDeep)
