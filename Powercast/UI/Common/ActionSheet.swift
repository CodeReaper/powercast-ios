import Foundation
import UIKit

typealias ActionSheetAction = () -> Void

enum ActionSheetOption {
    case title(text: String)
    case message(text: String)
    case style(preference: UIAlertController.Style)
    case cancel(text: String, action: ActionSheetAction?)
    case button(text: String, action: ActionSheetAction)
}

extension UIAlertController {
    static func build(with options: [ActionSheetOption]) -> UIAlertController {
        let title = options.compactMap {
            switch $0 {
            case .title(let text): return text
            default: return nil
            }
        }.first ?? ""

        let message = options.compactMap {
            switch $0 {
            case .message(let text): return text
            default: return nil
            }
        }.first ?? ""

        let style = options.compactMap {
            switch $0 {
            case .style(let preference): return preference
            default: return nil
            }
        }.first ?? UIAlertController.Style.actionSheet

        let actionSheet = UIAlertController(title: title, message: message, preferredStyle: style)
        for option in options {
            switch option {
            case let .cancel(text, action):
                actionSheet.addAction(UIAlertAction(title: text, style: .cancel, handler: { _ in action?() }))
            case let .button(text, action):
                actionSheet.addAction(UIAlertAction(title: text, style: .default, handler: { _ in action() }))
            case .title, .message, .style:
                break
            }
        }
        return actionSheet
    }
}
