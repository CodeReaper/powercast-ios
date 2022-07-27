import UIKit

struct Font {
    static func listAll() {
        for family in UIFont.familyNames.sorted() {
            let names = UIFont.fontNames(forFamilyName: family)
            print("Family: \(family) Font names: \(names)")
        }
    }

    private static let cooperHewittFonts: [UIFont.TextStyle: UIFont] = [
        .largeTitle: UIFont(name: "CooperHewitt-Book", size: 34)!,
        .title1: UIFont(name: "CooperHewitt-Book", size: 28)!,
        .title2: UIFont(name: "CooperHewitt-Book", size: 22)!,
        .title3: UIFont(name: "CooperHewitt-Book", size: 20)!,
        .headline: UIFont(name: "CooperHewitt-Bold", size: 17)!,
        .body: UIFont(name: "CooperHewitt-Book", size: 17)!,
        .callout: UIFont(name: "CooperHewitt-Book", size: 16)!,
        .subheadline: UIFont(name: "CooperHewitt-Book", size: 15)!,
        .footnote: UIFont(name: "CooperHewitt-Book", size: 13)!,
        .caption1: UIFont(name: "CooperHewitt-Book", size: 12)!,
        .caption2: UIFont(name: "CooperHewitt-Book", size: 11)!
    ]

    static func cooperHewitt(for style: UIFont.TextStyle) -> UIFont {
        return UIFontMetrics(forTextStyle: style).scaledFont(for: cooperHewittFonts[style]!)
    }

    static func alexBrush(size: CGFloat) -> UIFont {
        return UIFont(name: "AlexBrush-Regular", size: size)!
    }
}
