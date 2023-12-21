import UIKit

struct Font {
    static func listAll() {
        for family in UIFont.familyNames.sorted() {
            let names = UIFont.fontNames(forFamilyName: family)
            print("Family: \(family) Font names: \(names)")
        }
    }

    static func alexBrush(size: CGFloat) -> UIFont {
        return UIFont(name: "AlexBrush-Regular", size: size)!
    }
}
