import UIKit
import Lottie

extension View {
    static func buildLoadingView(color: UIColor = .black) -> AnimationView {
        var red = CGFloat.zero
        var green = CGFloat.zero
        var blue = CGFloat.zero
        var alpha = CGFloat.zero
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        let view = AnimationView(name: Animations.connecting)
        view.loopMode = .loop
        view.setValueProvider(
            ColorValueProvider(Color(r: red, g: green, b: blue, a: alpha, denominator: .One)),
            keypath: AnimationKeypath(keypath: "**.Color")
        )
        return view
    }
}
