import UIKit
import SugarKit

class StackviewCell: UITableViewCell {
    let views = Stack.views(on: .horizontal, inset: NSDirectionalEdgeInsets(top: 7, leading: 20, bottom: 7, trailing: 20))
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        views.layout(in: contentView) { make, its in
            make(its.leadingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.leadingAnchor))
            make(its.trailingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.trailingAnchor))
            make(its.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor))
            make(its.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor))
            make(its.heightAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.heightAnchor))
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        views.arrangedSubviews.forEach {
            views.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
    }
}
