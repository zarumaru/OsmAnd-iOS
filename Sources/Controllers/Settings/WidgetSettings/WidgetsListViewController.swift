//
//  OAWidgetsListViewController.swift
//  OsmAnd Maps
//
//  Created by Paul on 24.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import UIKit
import SafariServices

@objc(OAWidgetsListViewController)
@objcMembers
class WidgetsListViewController: OABaseNavbarSubviewViewController {

    static let kWidgetAddedNotification = "onWidgetAdded"

    private let kPageKey = "page_"
    private let kPageNumberKey = "page_number"
    private let kNoWidgetsKey = "noWidgets"
    private let kWidgetsInfoKey = "widget_info"
    private static let enabledWidgetsFilter = Int(KWidgetModeAvailable | kWidgetModeEnabled)

    let panels = WidgetsPanel.values

    private var widgetPanel: WidgetsPanel! {
        didSet {
            navigationItem.title = getTitle()
            updateUIAnimated(nil)
        }
    }

    private var editMode: Bool = false {
        didSet {
            tableView.setEditing(editMode, animated: true)
            if tableData.hasChanged || tableData.sectionCount() == 0 {
                updateUIAnimated(nil)
            } else {
                updateWithoutData()
            }
        }
    }

    private var selectedAppMode: OAApplicationMode {
        get {
            OAAppSettings.sharedManager().applicationMode.get()
        }
    }

    lazy private var widgetRegistry = OARootViewController.instance().mapPanel.mapWidgetRegistry!
    lazy private var widgetsSettingsHelper = WidgetsSettingsHelper(appMode: selectedAppMode)

    // MARK: - Initialization

    init(widgetPanel: WidgetsPanel!) {
        self.widgetPanel = widgetPanel
        super.init()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func registerNotifications() {
        addNotification(NSNotification.Name(kWidgetVisibilityChangedMotification), selector: #selector(onWidgetStateChanged))
        addNotification(NSNotification.Name(Self.kWidgetAddedNotification), selector: #selector(onWidgetAdded(notification:)))
    }

    // MARK: - Base setup UI

    override func createSubview() -> UIView! {
        if editMode {
            return nil
        }
        let segmentedControl = UISegmentedControl(items: [
            UIImage(named: "ic_custom20_screen_side_left")!,
            UIImage(named: "ic_custom20_screen_side_right")!,
            UIImage(named: "ic_custom20_screen_side_top")!,
            UIImage(named: "ic_custom20_screen_side_bottom")!])
        segmentedControl.selectedSegmentIndex = panels.firstIndex(of: widgetPanel) ?? 0
        segmentedControl.addTarget(self, action: #selector(segmentedControlValueChanged(_:)), for: .valueChanged)
        return segmentedControl
    }

    @objc private func segmentedControlValueChanged(_ control: UISegmentedControl) {
        widgetPanel = panels[control.selectedSegmentIndex]
    }

    // MARK: - Selectors

    override func onGestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer!) -> Bool {
        if gestureRecognizer == navigationController?.interactivePopGestureRecognizer {
            if editMode, tableData.hasChanged {
                showUnsavedChangesAlert(shouldDismiss: true)
                return false
            }
        }
        return true
    }

    private func showUnsavedChangesAlert(shouldDismiss: Bool) {
        let alert = UIAlertController.init(title: localizedString("unsaved_changes"),
                                                              message: localizedString("unsaved_changes_will_be_lost_discard"),
                                                              preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: localizedString("shared_string_discard"), style: .destructive) { [weak self] _ in
            guard let self else { return }
            editMode = false
            if shouldDismiss {
                dismiss()
            }
        })
        alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))
        let popPresenter = alert.popoverPresentationController
        popPresenter?.barButtonItem = getLeftNavbarButton()
        popPresenter?.permittedArrowDirections = UIPopoverArrowDirection.any

        present(alert, animated: true)
    }

    override func onLeftNavbarButtonPressed() {
        if editMode {
            if tableData.hasChanged {
                showUnsavedChangesAlert(shouldDismiss: false)
            } else {
                editMode = false
            }
            return
        }
        super.onLeftNavbarButtonPressed()
    }

    override func onRightNavbarButtonPressed() {
        if editMode {
            reorderWidgets()
            editMode = false
        }
    }

    override func onTopButtonPressed() {
        let vc = WidgetGroupListViewController()
        vc.widgetPanel = widgetPanel
        show(vc)
    }

    override func onBottomButtonPressed() {
        if editMode {
            let section = tableData.sectionData(for: tableData.sectionCount() - 1)
            let row = section.createNewRow()
            row.key = kPageKey
            row.cellType = OASimpleTableViewCell.getIdentifier()
            updatePageNumbers()
            tableView.reloadData()
            updateBottomButtons()
        } else {
            editMode = true
        }
    }

    @objc private func onWidgetAdded(notification: NSNotification) {
        let widget = (notification.object as? MapWidgetInfo) ?? nil
        if let newWidget = widget {
            let lastSection = tableData.sectionCount() - 1
            let lastSectionData = tableData.sectionData(for: lastSection)
            createWidgetItem(newWidget, lastSectionData)
            if editMode {
                DispatchQueue.main.async { [weak self] in
                    self?.tableView.reloadData()
                    self?.updateBottomButtons()
                }
            } else {
                if let userInfo = notification.userInfo as? [String: Any] {
                    reorderWidgets(with: userInfo)
                } else {
                    reorderWidgets()
                }
                updateUIAnimated(nil)
            }
        }
    }

    @objc private func onWidgetStateChanged() {
        if !editMode {
            updateUIAnimated(nil)
        }
    }

    @objc func onButtonClicked(sender: UIButton) {
        let indexPath: IndexPath = IndexPath(row: sender.tag & 0x3FF, section: sender.tag >> 10)
        let item: OATableRowData = tableData.item(for: indexPath)
        if item.key == kNoWidgetsKey {
            onTopButtonPressed()
        }
    }

    // MARK: - Additions

    private func reorderWidgets(with widgetParams: [String: Any]? = nil) {
        var orders = [[String]]()
        var currPage = [String]()
        for i in 0..<tableData.sectionData(for: 0).rowCount() {
            let rowData = tableData.sectionData(for: 0).getRow(i)
    
            if rowData.key == kPageKey && i != 0 {
                orders.append(currPage)
                currPage = [String]()
            }
            
            if let row = rowData.obj(forKey: kWidgetsInfoKey) as? MapWidgetInfo {
                currPage.append(row.key)
            }
        }
        orders.append(currPage)
    
        WidgetUtils.reorderWidgets(orderedWidgetPages: orders,
                                   panel: widgetPanel,
                                   selectedAppMode: selectedAppMode,
                                   widgetParams: widgetParams)
    }
}

// MARK: - Table data
extension WidgetsListViewController {

    override func generateData() {
        tableData.clearAllData()
        updateEnabledWidgets()
        tableData.resetChanges()
    }

    override func getRow(_ indexPath: IndexPath!) -> UITableViewCell! {
        let item = tableData.item(for: indexPath)
        var outCell: UITableViewCell? = nil
        if item.cellType == OASimpleTableViewCell.getIdentifier() {
            var cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.getIdentifier()) as? OASimpleTableViewCell
            if cell == nil {
                let nib = Bundle.main.loadNibNamed(OASimpleTableViewCell.getIdentifier(), owner: self, options: nil)
                cell = nib?.first as? OASimpleTableViewCell
                cell?.descriptionVisibility(false)
            }
            if let cell = cell {
                let isPageCell = item.key == kPageKey
                cell.titleLabel.text = isPageCell ? String(format:localizedString("shared_string_page_number"), item.integer(forKey: kPageNumberKey) + 1) : item.title
                cell.leftIconView.image = UIImage(named: item.iconName ?? "")
                cell.leftIconVisibility(!isPageCell)
                cell.accessoryType = isPageCell ? .none : .disclosureIndicator
                cell.selectionStyle = !tableView.isEditing && isPageCell ? .none : .default
                cell.titleLabel.textColor = isPageCell ? .textColorSecondary : .textColorPrimary
            }
            return cell
        } else if item.cellType == OALargeImageTitleDescrTableViewCell.getIdentifier() {
            var cell = tableView.dequeueReusableCell(withIdentifier: OALargeImageTitleDescrTableViewCell.getIdentifier()) as? OALargeImageTitleDescrTableViewCell
            if cell == nil {
                let nib = Bundle.main.loadNibNamed(OALargeImageTitleDescrTableViewCell.getIdentifier(), owner: self, options: nil)
                cell = nib?.first as? OALargeImageTitleDescrTableViewCell
                cell?.selectionStyle = .none
            }
            if let cell = cell {
                cell.titleLabel?.text = item.title
                cell.titleLabel?.accessibilityLabel = item.title
                cell.descriptionLabel?.text = item.descr
                cell.descriptionLabel?.accessibilityLabel = item.descr
                cell.cellImageView?.image = UIImage.templateImageNamed(item.iconName)
                cell.cellImageView?.tintColor = item.iconTintColor
                cell.button?.setTitle(item.obj(forKey: "buttonTitle") as? String, for: .normal)
                cell.button?.accessibilityLabel = item.obj(forKey: "buttonTitle") as? String
                cell.button?.removeTarget(nil, action: nil, for: .allEvents)
                cell.button?.tag = indexPath.section << 10 | indexPath.row
                cell.button?.addTarget(self, action: #selector(onButtonClicked(sender:)), for: .touchUpInside)
            }
            outCell = cell

            let update: Bool = outCell?.needsUpdateConstraints() ?? false
            if update {
                outCell?.setNeedsUpdateConstraints()
            }
        }

        return outCell
    }

    override func onRowSelected(_ indexPath: IndexPath!) {
        let item = tableData.item(for: indexPath)
        if item.cellType == OASimpleTableViewCell.getIdentifier() {
            let vc = WidgetConfigurationViewController()!
            vc.selectedAppMode = selectedAppMode
            vc.widgetInfo = item.obj(forKey: kWidgetsInfoKey) as? MapWidgetInfo
            vc.widgetPanel = widgetPanel
            show(vc)
        }
    }

    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        let item = tableData.item(for: indexPath)
        let isFirstPageCell = item.key == kPageKey && indexPath.row == 0
        let isNoWidgetsCell = item.key == kNoWidgetsKey
        let isPageCell = item.key == kPageKey
        return editMode && !isNoWidgetsCell && !isFirstPageCell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let item = tableData.item(for: indexPath)
        let isFirstPageCell = item.key == kPageKey && indexPath.row == 0
        let isNoWidgetsCell = item.key == kNoWidgetsKey
        return editMode && !isNoWidgetsCell && !isFirstPageCell
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let item = tableData.item(for: sourceIndexPath)
        let isPageCell = item.key == kPageKey
        tableData.removeRow(at: sourceIndexPath)
        let movedIndexPath = destinationIndexPath.row == 0 ? IndexPath(row: 1, section: destinationIndexPath.section) : destinationIndexPath
        tableData.addRow(at: movedIndexPath, row: item)
        updatePageNumbers()
        tableView.reloadData()
        updateBottomButtons()
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let item = tableData.item(for: indexPath)
            tableData.removeRow(at: indexPath)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            if let widgetInfo = item.obj(forKey: kWidgetsInfoKey) as? MapWidgetInfo {
                widgetRegistry.enableDisableWidget(for: selectedAppMode, widgetInfo: widgetInfo, enabled: NSNumber(value: false), recreateControls: true)
            }
            if !editMode {
                reorderWidgets()
            }
            let isPageCell = item.key == kPageKey
            if isPageCell {
                updatePageNumbers()
                tableView.reloadData()
            }
            updateBottomButtons()
        }
    }

    override func tableView(_ tableView: UITableView,
                            targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath,
                            toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        if proposedDestinationIndexPath.row == 0 && proposedDestinationIndexPath.section == 0 {
            return IndexPath(row: 1, section: 0)
        }
        return proposedDestinationIndexPath
    }

    private func updateEnabledWidgets() {
        let enabledWidgets = widgetRegistry.getWidgetsForPanel(selectedAppMode, filterModes: Self.enabledWidgetsFilter, panels: [widgetPanel])!
        let noEnabledWidgets = enabledWidgets.count == 0
        if noEnabledWidgets && !editMode {
            var iconName = "ic_custom_screen_side_left_48"
            if widgetPanel == .topPanel {
                iconName = "ic_custom_screen_side_top_48"
            } else if widgetPanel == .rightPanel {
                iconName = "ic_custom_screen_side_right_48"
            } else if widgetPanel == .bottomPanel {
                iconName = "ic_custom_screen_side_bottom_48"
            }
            let section = tableData.createNewSection()
            let row = section.createNewRow()
            row.cellType = OALargeImageTitleDescrTableViewCell.getIdentifier()
            row.key = kNoWidgetsKey
            row.title = localizedString("no_widgets_here_yet")
            row.descr = localizedString("no_widgets_descr")
            row.iconName = iconName
            row.iconTintColor = UIColor.iconColorDefault
            row.setObj(localizedString("add_widget"), forKey: "buttonTitle")
        } else {
            if widgetPanel.isPagingAllowed() {
                let pagedWidgets = widgetRegistry.getPagedWidgets(forPanel: selectedAppMode, panel: widgetPanel, filterModes: Self.enabledWidgetsFilter)!
                tableData.clearAllData()
                tableData.createNewSection()
                for i in 0..<pagedWidgets.count {
                    createWidgetItems(pagedWidgets[i], i)
                }
            } else {
                let widgets = widgetRegistry.getWidgetsForPanel(selectedAppMode, filterModes: Self.enabledWidgetsFilter, panels: [widgetPanel])
                if let widgets {
                    tableData.clearAllData()
                    tableData.createNewSection()
                    createWidgetItems(widgets, 0)
                }
            }
        }
    }

    private func createWidgetItems(_ widgets: NSOrderedSet, _ pageIndex: Int) {
        let section = tableData.sectionData(for: 0)
        let row = section.createNewRow()
        row.key = kPageKey
        row.cellType = OASimpleTableViewCell.getIdentifier()
        row.setObj(pageIndex, forKey: kPageNumberKey)

        let sortedWidgets = (widgets.array as! [MapWidgetInfo]).sorted { $0.priority < $1.priority }
        for widget in sortedWidgets {
            createWidgetItem(widget, section)
        }
    }

    private func createWidgetItem(_ widget: MapWidgetInfo, _ section: OATableSectionData) {
        if section.rowCount() > 0 && section.getRow(0).key != kPageKey {
            section.addRow(OATableRowData(), position: 0)
            let row = section.getRow(0)
            row.key = kPageKey
            row.cellType = OASimpleTableViewCell.getIdentifier()
        }
        
        let row = section.createNewRow()
        row.setObj(widget, forKey: kWidgetsInfoKey)
        row.iconName = widget.widget.widgetType?.iconName
        row.title = widget.getTitle()
        row.descr = widget.getMessage()
        row.cellType = OASimpleTableViewCell.getIdentifier()
    }
    
    private func updatePageNumbers() {
        if tableData.sectionCount() > 0 {
            let section = tableData.sectionData(for: 0)
            var foundedPageIndex = 0
            for i in 0..<section.rowCount() {
                let row = section.getRow(i)
                if row.key == kPageKey {
                    row.setObj(foundedPageIndex, forKey: kPageNumberKey)
                    foundedPageIndex += 1
                }
            }
        }
    }
}

extension WidgetsListViewController {

    //MARK: - Base UI

    override func getTitle() -> String! {
        widgetPanel.title
    }

    override func getBottomAxisMode() -> NSLayoutConstraint.Axis {
        .horizontal
    }

    override func isNavbarSeparatorVisible() -> Bool {
        editMode
    }

    override func getLeftNavbarButtonTitle() -> String! {
        editMode ? localizedString("shared_string_cancel") : nil
    }

    override func getRightNavbarButtons() -> [UIBarButtonItem]! {
        var menuElements: [UIMenuElement]?
        var resetAlert: UIAlertController?
        if !editMode {
            resetAlert = UIAlertController.init(title: self.widgetPanel.title,
                                                message: localizedString("reset_all_settings_desc"),
                                                preferredStyle: .actionSheet)
            let resetAction: UIAction  = UIAction(title: localizedString("reset_to_default"),
                                                  image: UIImage.init(systemName: "gobackward")) { [weak self] _ in
                guard let self = self else { return }

                resetAlert!.addAction(UIAlertAction(title: localizedString("shared_string_reset"), style: .destructive) { UIAlertAction in
                    self.widgetsSettingsHelper.resetWidgetsForPanel(panel: self.widgetPanel)
                    OARootViewController.instance().mapPanel.recreateAllControls()
                    self.updateUIAnimated(nil)
                })
                resetAlert!.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))
                self.present(resetAlert!, animated: true)
            }
            let copyAction: UIAction = UIAction(title: localizedString("copy_from_other_profile"),
                                                image: UIImage.init(systemName: "doc.on.doc")) { [weak self] _ in
                guard let self = self else { return }

                let bottomSheet: OACopyProfileBottomSheetViewControler = OACopyProfileBottomSheetViewControler.init(mode: self.selectedAppMode)
                bottomSheet.delegate = self;
                bottomSheet.present(in: self)
            }
            let helpAction: UIAction = UIAction(title: localizedString("shared_string_help"),
                                                image: UIImage.init(systemName: "questionmark.circle")) { [weak self] _ in
                guard let self = self else { return }

                self.openSafariWithURL("https://docs.osmand.net/docs/user/widgets/configure-screen")
            }
            let helpMenuAction: UIMenu = UIMenu(options: .displayInline, children: [helpAction])
            menuElements = [resetAction, copyAction, helpMenuAction]
        }
        let menu: UIMenu? = editMode ? nil : UIMenu(children: menuElements ?? [])
        let button = createRightNavbarButton(editMode ? localizedString("shared_string_done") : nil,
                                             iconName: editMode ? nil : "ic_navbar_overflow_menu_stroke",
                                             action: #selector(onRightNavbarButtonPressed),
                                             menu: menu)
        if !editMode {
            button?.accessibilityLabel = localizedString("shared_string_options")
        }
        let popover = resetAlert?.popoverPresentationController
        popover?.barButtonItem = button
        return [button!]
    }

    override func getTopButtonTitle() -> String {
        let enabledWidgets = widgetRegistry.getWidgetsForPanel(selectedAppMode,
                                                               filterModes: Self.enabledWidgetsFilter,
                                                               panels: [widgetPanel])!
        return editMode || enabledWidgets.count > 0 ? localizedString("add_widget") : ""
    }

    override func getBottomButtonTitle() -> String {
        let enabledWidgets = widgetRegistry.getWidgetsForPanel(selectedAppMode,
                                                               filterModes: Self.enabledWidgetsFilter,
                                                               panels: [widgetPanel])!
        if editMode || enabledWidgets.count > 0 {
            return editMode && (widgetPanel == WidgetsPanel.topPanel || widgetPanel == WidgetsPanel.bottomPanel) ? "" : localizedString(editMode ? "add_page" : "shared_string_edit")
        } else {
            return ""
        }
    }

    override func getTopButtonColorScheme() -> EOABaseButtonColorScheme {
        return .graySimple
    }

    override func getBottomButtonColorScheme() -> EOABaseButtonColorScheme {
        if editMode {
            for i in 0..<tableData.sectionCount() {
                let section = tableData.sectionData(for: i)
                if section.rowCount() == 1 {
                    return .inactive
                }
            }
        }
        return .graySimple
    }

}

// MARK: - SFSafariViewControllerDelegate

extension WidgetsListViewController: SFSafariViewControllerDelegate {

    @nonobjc func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        controller.dismiss(animated: true)
    }

    func openSafariWithURL(_ url: String) {
        let safariViewController:SFSafariViewController = SFSafariViewController(url: URL(string: url)!)
        safariViewController.delegate = self
        self.present(safariViewController, animated:true)
    }
}

// MARK: - OACopyProfileBottomSheetDelegate

extension WidgetsListViewController: OACopyProfileBottomSheetDelegate {

    func onCopyProfileCompleted() {
    }

    func onCopyProfile(_ fromAppMode: OAApplicationMode!) {
        widgetsSettingsHelper.copyWidgetsForPanel(fromAppMode: fromAppMode, panel: self.widgetPanel)
        OARootViewController.instance().mapPanel.recreateAllControls()
        self.updateUIAnimated(nil)
    }
}
