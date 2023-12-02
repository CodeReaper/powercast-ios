import UIKit
import SugarKit

class NotificationViewController: ViewController {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let triggerPicker = UIDatePicker()
    private let startPicker = UIPickerView()
    private let durationPicker = UIPickerView()
    private let toggle = UISwitch(frame: .zero)

    private let startingHours = Array(stride(from: 0, to: 24, by: 1))
    private let durationHours = Array(stride(from: 1, to: 25, by: 1))

    private let state: StateRepository
    private let existingNotification: Bool
    private let originalNotification: Notification

    private var notification: Notification

    private lazy var saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(didTapSave))
    private lazy var cancelButton = UIBarButtonItem(barButtonSystemItem: .undo, target: self, action: #selector(didTapCancel))

    init(navigation: AppNavigation, state: StateRepository, notification: Notification?) {
        self.state = state
        self.existingNotification = notification != nil
        self.originalNotification = notification ?? Notification.create()
        self.notification = self.originalNotification
        super.init(navigation: navigation)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Notification" // FIXME: notification.title

        tableView.sectionHeaderHeight = UITableView.automaticDimension
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        tableView.showsVerticalScrollIndicator = false
        tableView
            .set(datasource: self, delegate: self)
            .set(backgroundColor: .tableBackground)
            .registerClass(DurationCell.self)
            .registerClass(DateSelectionCell.self)
            .registerClass(ToggleCell.self)
            .registerClass(MessageCell.self)
            .layout(in: view) { make, its in
                make(its.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor))
                make(its.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor))
                make(its.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor))
                make(its.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor))
            }

        triggerPicker.preferredDatePickerStyle = .inline
        triggerPicker.datePickerMode = .time
        triggerPicker.minuteInterval = 15
        triggerPicker.addTarget(self, action: #selector(didChangeTrigger), for: .valueChanged)

        for picker in [startPicker, durationPicker] {
            picker.dataSource = self
            picker.delegate = self
        }

        toggle.onTintColor = .toggleTint
        toggle.addTarget(self, action: #selector(didTapToggle), for: .valueChanged)

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
        navigationItem.setRightBarButton(hasChanges || !existingNotification ? saveButton : nil, animated: true)
        triggerPicker.setDate(.now.startOfDay.addingTimeInterval(TimeInterval(notification.fireOffset)), animated: true)
        startPicker.selectRow(startingHours.firstIndex(of: Int(notification.dateOffset)) ?? 0, inComponent: 0, animated: true)
        durationPicker.selectRow(durationHours.firstIndex(of: Int(notification.durationOffset)) ?? 0, inComponent: 0, animated: true)
        toggle.setOn(notification.enabled, animated: true)
        tableView.reloadSections(IndexSet(integer: 3), with: .automatic)
    }
}

extension NotificationViewController: UITableViewDelegate, UITableViewDataSource {
    // FIXME: translations
    private class DurationCell: StackviewCell {
        func update(with firstView: UIPickerView, and secondView: UIPickerView) -> Self {
            views.directionalLayoutMargins.top = 15
            views.addArrangedSubview(Stack.views(on: .vertical, Label(text: "Starting at hour").aligned(to: .center), firstView))
            views.addArrangedSubview(Stack.views(on: .vertical, Label(text: "Duration in hours").aligned(to: .center), secondView))
            return self
        }
    }

    private class ToggleCell: StackviewCell {
        func update(with view: UISwitch) -> Self {
            views.addArrangedSubview(Label(text: "Enabled"))
            views.addArrangedSubview(view.updateContentHuggingPriority(.required, for: .horizontal))
            return self
        }
    }

    private class DateSelectionCell: StackviewCell {
        func update(with view: UIDatePicker) -> Self {
            views.addArrangedSubview(Label(text: "At selected time"))
            views.addArrangedSubview(view.updateContentHuggingPriority(.required, for: .horizontal))
            return self
        }
    }

    private class MessageCell: StackviewCell {
        func update(with message: String) -> Self {
            views.addArrangedSubview(Label(text: message))
            backgroundColor = .clear
            separatorInset = UIEdgeInsets(top: 0, left: bounds.size.width, bottom: 0, right: bounds.size.width)
            return self
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch (indexPath.section, indexPath.row) {
        case (0, 0): tableView.dequeueReusableCell(ToggleCell.self, forIndexPath: indexPath).update(with: toggle)
        case (1, 0): tableView.dequeueReusableCell(DateSelectionCell.self, forIndexPath: indexPath).update(with: triggerPicker)
        case (2, 0): tableView.dequeueReusableCell(DurationCell.self, forIndexPath: indexPath).update(with: startPicker, and: durationPicker)
        case (3, 0): tableView.dequeueReusableCell(MessageCell.self, forIndexPath: indexPath).update(with: notification.description)
        default: tableView.dequeueReusableCell(UITableViewCell.self, forIndexPath: indexPath)
        }
    }

    // FIXME: *
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 1: return "Trigger"
        case 2: return "Period"
        case 3: return "Description"
        default: return ""
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        4
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
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
