import UIKit
import Lottie

class AnimationView {
    class Electricity: LottieAnimationView {
        convenience init(color: UIColor = .black, mode: LottieLoopMode = .loop) {
            self.init(name: Animations.electricity)
            loopMode = mode
            setValueProvider(
                AnimationView.provider(for: color),
                keypath: AnimationKeypath(keypath: "**.Color")
            )
        }
    }

    class Loading: LottieAnimationView {
        convenience init(color: UIColor = .black, mode: LottieLoopMode = .loop) {
            self.init(name: Animations.loading)
            loopMode = mode
            setValueProvider(
                AnimationView.provider(for: color),
                keypath: AnimationKeypath(keypath: "**.Color")
            )
        }
    }

    class LocationSelection: LottieAnimationView {
        convenience init(mode: LottieLoopMode = .loop) {
            self.init(name: Animations.locationSelection)
            loopMode = mode
        }
    }

    class QuestionMark: LottieAnimationView {
        convenience init(color: UIColor = .white, mode: LottieLoopMode = .loop) {
            self.init(name: Animations.questionMark)
            loopMode = mode
            setValueProvider(
                AnimationView.provider(for: color),
                keypath: AnimationKeypath(keypath: "**.Color")
            )
        }
    }

    private static func provider(for color: UIColor) -> ColorValueProvider {
        var red = CGFloat.zero
        var green = CGFloat.zero
        var blue = CGFloat.zero
        var alpha = CGFloat.zero
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return ColorValueProvider(
            LottieColor(r: red, g: green, b: blue, a: alpha, denominator: .One)
        )
    }
}
