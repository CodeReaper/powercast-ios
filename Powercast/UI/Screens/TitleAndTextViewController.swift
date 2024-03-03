import UIKit
import SugarKit

class TitleAndTextViewController: ViewController {
    private let content: String

    init(navigation: AppNavigation, title: String, content: String) {
        self.content = content
        super.init(navigation: navigation)
        self.title = title
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let scrollView = UIScrollView().setup(matching: view, in: view)
        scrollView.alwaysBounceVertical = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never

        let textView = UITextView()
        textView.text = content
        textView.textColor = .labelText
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.backgroundColor = .clear
        textView.isEditable = false
        textView.dataDetectorTypes = .link
        textView.isScrollEnabled = false
        textView.linkTextAttributes = [
            .foregroundColor: UIColor.labelLinkText,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]

        Stack
            .views(
                aligned: .leading,
                on: .vertical,
                inset: NSDirectionalEdgeInsets(top: 25, leading: 15, bottom: 5, trailing: 15),
                textView
            )
            .layout(in: scrollView) { make, its in
                make(its.topAnchor.constraint(equalTo: scrollView.topAnchor))
                make(its.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor))
                make(its.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor))
                make(its.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor))
                make(its.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor))
            }
    }
}
