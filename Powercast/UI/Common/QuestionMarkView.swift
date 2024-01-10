import UIKit
import Lottie
import SugarKit

extension View {
    static func buildQuestionMarkView(color: UIColor = .black) -> LottieAnimationView {
        var red = CGFloat.zero
        var green = CGFloat.zero
        var blue = CGFloat.zero
        var alpha = CGFloat.zero
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        let view = LottieAnimationView(name: Animations.questionMark)
        view.loopMode = .loop
        view.setValueProvider(
            ColorValueProvider(
                LottieColor(r: red, g: green, b: blue, a: alpha, denominator: .One)
            ),
            keypath: AnimationKeypath(keypath: "**.Color")
        )
        return view
    }
}