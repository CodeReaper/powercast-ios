import UIKit
import SugarKit

class NotificationViewController: ViewController {
    private let views = Stack.views(on: .vertical, spacing: 15, inset: NSDirectionalEdgeInsets(top: 25, leading: 15, bottom: 5, trailing: 15))
    private let label = Label()
    private let triggerPicker = UIDatePicker()
    private let startPicker = UIPickerView()
    private let durationPicker = UIPickerView()
    private let toggle = UISwitch(frame: .zero)

    private let startingHours = Array(stride(from: 0, to: 24, by: 1))
    private let durationHours = Array(stride(from: 1, to: 25, by: 1))

    private let state: StateRepository
    private let originalNotification: Notification

    private var notification: Notification

    private lazy var saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(didTapSave))
    private lazy var cancelButton = UIBarButtonItem(barButtonSystemItem: .undo, target: self, action: #selector(didTapCancel))

    init(navigation: AppNavigation, state: StateRepository, notification: Notification?) {
        self.state = state
        self.originalNotification = notification ?? Notification.create()
        self.notification = self.originalNotification
        super.init(navigation: navigation)
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

        views.layout(in: scrollView) { make, its in
            make(its.topAnchor.constraint(equalTo: scrollView.topAnchor))
            make(its.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor))
            make(its.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor))
            make(its.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor))
            make(its.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor))
        }

        triggerPicker.preferredDatePickerStyle = .inline
        triggerPicker.datePickerMode = .time
        triggerPicker.minuteInterval = 15
        triggerPicker.addTarget(self, action: #selector(didChangeTrigger), for: .valueChanged)

        for picker in [startPicker, durationPicker] {
            picker.dataSource = self
            picker.delegate = self
            picker.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([picker.heightAnchor.constraint(equalToConstant: 162)])
        }

        toggle.onTintColor = .toggleTint
        toggle.addTarget(self, action: #selector(didTapToggle), for: .valueChanged)

        // FIXME: translations
        views.addArrangedSubview(Stack.views(distributed: .fill, Label(text: "Enabled"), toggle.updateContentHuggingPriority(.required, for: .horizontal)))
        views.addArrangedSubview(Stack.views(distributed: .fillEqually, Label(text: "start").aligned(to: .center), Label(text: "duration").aligned(to: .center)))
        views.addArrangedSubview(Stack.views(distributed: .fillEqually, startPicker, durationPicker))
        views.addArrangedSubview(Stack.views(distributed: .fillEqually, Label(text: "Trigger"), triggerPicker))
        views.addArrangedSubview(label)

        update()
    }

    @objc private func didTapCancel() {
        notification = originalNotification
        update()
    }

    @objc private func didTapSave() {
        state.update(notification: notification)
        navigationController?.popViewController(animated: true)
    }

    @objc private func didTapToggle() {
        notification = notification.copy(enabled: toggle.isOn)
        update()
    }

    @objc private func didChangeTrigger() {
        let date = triggerPicker.date
        let seconds = date.timeIntervalSince1970 - date.startOfDay.timeIntervalSince1970
        if seconds < 0 {
            triggerPicker.date = date.startOfDay.addingTimeInterval(TimeInterval(notification.fireOffset))
        } else {
            notification = notification.copy(fireOffset: UInt(triggerPicker.date.timeIntervalSince1970 - triggerPicker.date.startOfDay.timeIntervalSince1970))
        }
        update()
    }

    @objc private func update() {
        let hasChanges = originalNotification != notification
        navigationItem.setHidesBackButton(hasChanges, animated: true)
        navigationItem.setLeftBarButton(hasChanges ? cancelButton : nil, animated: true)
        navigationItem.setRightBarButton(hasChanges ? saveButton : nil, animated: true)
        title = "Notification" // FIXME: notification.title
        label.text = notification.description
        triggerPicker.setDate(.now.startOfDay.addingTimeInterval(TimeInterval(notification.fireOffset)), animated: true)
        startPicker.selectRow(startingHours.firstIndex(of: Int(notification.dateOffset)) ?? 0, inComponent: 0, animated: true)
        durationPicker.selectRow(durationHours.firstIndex(of: Int(notification.durationOffset)) ?? 0, inComponent: 0, animated: true)
        toggle.setOn(notification.enabled, animated: true)
    }
}

extension NotificationViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch true {
        case pickerView === startPicker: return startingHours.count
        case pickerView === durationPicker: return durationHours.count
        default: return 0
        }
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch true {
        case pickerView === startPicker: return "\(startingHours[row])"
        case pickerView === durationPicker: return "\(durationHours[row])"
        default: return nil
        }
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch true {
        case pickerView === startPicker:
            notification = notification.copy(dateOffset: UInt(startingHours[row]))
        case pickerView === durationPicker:
            notification = notification.copy(durationOffset: UInt(durationHours[row]))
        default: break
        }
        update()
    }
}

private extension Notification {
    static func create() -> Notification {
        Notification(id: UUID().uuidString, enabled: true, fireOffset: 46800, dateOffset: 16, durationOffset: 5, lastDelivery: Date(timeIntervalSince1970: 0))
    }
}
