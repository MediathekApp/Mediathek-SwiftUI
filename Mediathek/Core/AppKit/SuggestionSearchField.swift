//
//  SuggestionTextField.swift
//  Mediathek
//
//  Created by Jon on 05.06.25.
//

#if os(macOS)
import AppKit
import SwiftUI

class SuggestionNSSearchField: NSSearchField {
    
    weak var suggestionDelegate: SuggestionNSSearchFieldDelegate?
    
    override func performKeyEquivalent(with event: NSEvent) -> Bool {

        guard event.type == .keyDown else {
            return super.performKeyEquivalent(with: event)
        }

        let keyCode = event.keyCode
        let isArrowKey = (keyCode == 0x7E || keyCode == 0x7D) // Up and Down arrow keys

        if isArrowKey {

            if let fieldEditor = self.currentEditor() as? NSTextView {
                let selectedRange = fieldEditor.selectedRange
                let textLength = fieldEditor.string.count

                switch keyCode {
                case 0x7E: // Up Arrow
                    // Check if the selection is at the very beginning of the text
                        let result = suggestionDelegate?.handleKeyEvent(event)
                        return result == true // Consume the event, don't pass to super
                case 0x7D: // Down Arrow
                    // Check if the selection is at the very end of the text
                    if selectedRange.location == textLength {
                        let result = suggestionDelegate?.handleKeyEvent(event)
                        return result == true // Consume the event, don't pass to super
                    }
                default:
                    break
                }
            }
        }

        if keyCode == 0x24 { // Enter key
            let result = suggestionDelegate?.handleKeyEvent(event)
            return result == true // Consume the event, don't pass to super
        }

        
        return super.performKeyEquivalent(with: event)
    }

}

protocol SuggestionNSSearchFieldDelegate: AnyObject {
    func handleKeyEvent(_ event: NSEvent) -> Bool
}

struct SuggestionSearchField: NSViewRepresentable {
    
    @Binding var text: String
    var onSelectSuggestion: (SearchRecommendation) -> Void
    var onSearch: (String) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func makeNSView(context: Context) -> NSSearchField {
        let searchField = SuggestionNSSearchField()
        searchField.delegate = context.coordinator
        searchField.suggestionDelegate = context.coordinator
        context.coordinator.searchField = searchField
        return searchField
    }
    
    func updateNSView(_ nsView: NSSearchField, context: Context) {
        nsView.stringValue = text
        context.coordinator.updateSuggestions(/*suggestions*/)
    }
    
    class Coordinator: NSObject, NSSearchFieldDelegate, NSTableViewDataSource, NSTableViewDelegate, SuggestionNSSearchFieldDelegate {
        var parent: SuggestionSearchField
        var popupWindow: NSWindow?
        var tableView: NSTableView!
        var filteredSuggestions: [SearchRecommendation] = []
        var searchField: NSSearchField?
        
        init(parent: SuggestionSearchField) {
            self.parent = parent
        }
        
        func controlTextDidChange(_ obj: Notification) {
            guard let field = obj.object as? NSSearchField else { return }
            parent.text = field.stringValue
            showSuggestions(for: field)
        }
        
        func controlTextDidEndEditing(_ obj: Notification) {
            DispatchQueue.main.async {
                self.hideSuggestions()
            }
        }
        
        
        func handleKeyEvent(_ event: NSEvent) -> Bool {
            guard popupWindow?.isVisible == true,
                  !filteredSuggestions.isEmpty else {
                let isReturn = event.keyCode == 36
                if isReturn {
                    parent.onSearch(parent.text)
                }
                return false
            }
            
            switch event.keyCode {
            case 125: // ⬇︎ Down arrow
                moveSelection(offset: 1)
                return true
            case 126: // ⬆︎ Up arrow
                if selectedIndex < 0 { return false }
                moveSelection(offset: -1)
                return true
            case 36:  // ⏎ Return
                if !confirmSelection() {
                    parent.onSearch(parent.text)
                }
                return true
            case 53:  // ⎋ Escape
                hideSuggestions()
                return true
            default:
                return false
            }
        }
        
        
        var selectedIndex: Int = -1
        
        func moveSelection(offset: Int) {
            let maxIndex = filteredSuggestions.count - 1
            selectedIndex = max(-1, min(maxIndex, selectedIndex + offset))
            if selectedIndex >= 0 {
                tableView?.selectRowIndexes(IndexSet(integer: selectedIndex), byExtendingSelection: false)
                tableView?.scrollRowToVisible(selectedIndex)
            }
            else {
                tableView?.selectRowIndexes(IndexSet(), byExtendingSelection: false)
            }
        }
        
        func confirmSelection() -> Bool {
            guard selectedIndex >= 0 && selectedIndex < filteredSuggestions.count else { return false }
            let selected = filteredSuggestions[selectedIndex]
            parent.text = selected.query
            parent.onSelectSuggestion(selected)
            hideSuggestions()
            return true
        }
        
        
        func updateSuggestions() {}
        
        func showSuggestions(for searchField: NSSearchField) {
            
            if popupWindow == nil {
                setupPopup(for: searchField)
            }
            
            let maxSuggestions: Int = 10
            
            // Filter 10 max
            filteredSuggestions = Array(RecommendationService.shared.searchRecommendations.filter {
                $0.query.lowercased().contains(searchField.stringValue.lowercased())
            }
            .prefix(maxSuggestions))

            selectedIndex = -1
            
            tableView.reloadData()
            
            if !filteredSuggestions.isEmpty {
                popupWindow?.orderFront(nil)
                updatePopupSize()
                updatePopupPosition()
            } else {
                hideSuggestions()
            }
        }
        
        func hideSuggestions() {
            popupWindow?.orderOut(nil)
            popupWindow?.close()
            popupWindow = nil
        }
        
        func updatePopupPosition() {
            guard let searchField = self.searchField else { return }
            
            
            guard let popupWindow = self.popupWindow else { return }
            
            
            guard let mainWindow = searchField.window else { return }
            
            let fieldFrameInWindow = searchField.convert(searchField.bounds, to: nil)
            let fieldFrameOnScreen = mainWindow.convertToScreen(fieldFrameInWindow)
            
            // Offset below the search field
            let popupOrigin = CGPoint(
                x: fieldFrameOnScreen.origin.x,
                y: fieldFrameOnScreen.origin.y - popupWindow.frame.height
            )
            
            popupWindow.setFrameOrigin(popupOrigin)
        }
        
        let paddingY: CGFloat = 5

        func updatePopupSize() {
            guard let popupWindow, let tableView else { return }

            let numberOfRows = tableView.numberOfRows
            let rowHeight = tableView.rowHeight
            let maxVisibleRows = 20

            let visibleRows = min(numberOfRows, maxVisibleRows)
            let height = CGFloat(visibleRows) * rowHeight + paddingY*2

            var frame = popupWindow.frame
            frame.size.height = height
            popupWindow.setFrame(frame, display: true, animate: true)
        }
        
        private func setupPopup(for searchField: NSSearchField) {
            
            let width: CGFloat = AppConfig.searchFieldWidth
            let height: CGFloat = 150

            tableView = NSTableView(frame: NSRect(x: 0, y: 0, width: width, height: height))
            tableView.translatesAutoresizingMaskIntoConstraints = false

            let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("SuggestionColumn"))
            column.width = width
            column.resizingMask = .autoresizingMask
            tableView.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
            tableView.addTableColumn(column)
            tableView.delegate = self
            tableView.dataSource = self
            tableView.headerView = nil
            tableView.target = self
            tableView.action = #selector(didClickRow)
            tableView.style = .plain

            
            let containerView = NSView(frame: NSRect(x: 0, y: 0, width: width, height: height + paddingY*2))
            containerView.translatesAutoresizingMaskIntoConstraints = false
            containerView.wantsLayer = true
            containerView.layer?.cornerRadius = 8.0
            
            
            let backgroundView = NSVisualEffectView(frame: containerView.bounds)
            backgroundView.material = NSVisualEffectView.Material.menu
            backgroundView.blendingMode = NSVisualEffectView.BlendingMode.behindWindow
            backgroundView.state = NSVisualEffectView.State.active
            backgroundView.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(backgroundView)

            NSLayoutConstraint.activate([
                backgroundView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                backgroundView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                backgroundView.topAnchor.constraint(equalTo: containerView.topAnchor),
                backgroundView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
            ])
            
            containerView.addSubview(tableView)
            
            tableView.sizeLastColumnToFit()

            NSLayoutConstraint.activate([
                tableView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                tableView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                tableView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 5),
                tableView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -5)
            ])

            
            popupWindow = NSPanel(
                contentRect: containerView.frame,
                styleMask: [.nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            popupWindow?.isOpaque = false
            popupWindow?.backgroundColor = .clear
            popupWindow?.level = .floating
            popupWindow?.hasShadow = true
            popupWindow?.contentView = containerView
            popupWindow?.hidesOnDeactivate = false
            
            // Attach to parent so it doesn’t auto-dismiss
            guard let parentWindow = searchField.window else { return }
            parentWindow.addChildWindow(popupWindow!, ordered: .above)
            
            
            let screenFrame = searchField.window?.convertToScreen(searchField.frame) ?? .zero
            let popupOrigin = CGPoint(x: screenFrame.origin.x, y: screenFrame.origin.y - containerView.frame.height)
            popupWindow?.setFrameOrigin(popupOrigin)
        }
        
        @objc func didClickRow() {
            let selectedRow = tableView.selectedRow
            guard selectedRow >= 0 else { return }
            let selected = filteredSuggestions[selectedRow]
            parent.text = selected.query
            parent.onSelectSuggestion(selected)
            hideSuggestions()
        }
        
        
        // MARK: - TableView Data Source
        
        func numberOfRows(in tableView: NSTableView) -> Int {
            return filteredSuggestions.count
        }
        
        func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
            let rowView = HoverableTableRowView()
            rowView.rowIndex = row
            rowView.hoverDelegate = self
            return rowView
        }
        
        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
            let identifier = NSUserInterfaceItemIdentifier("SuggestionCell")
            var cell = tableView.makeView(withIdentifier: identifier, owner: self) as? CustomTableCellView

            if cell == nil {
                cell = CustomTableCellView()
                cell?.identifier = identifier

                // MARK: - Create and Configure the Circle View
                let circle = NSView()
                circle.wantsLayer = true
                circle.layer?.cornerRadius = 2.5
                circle.layer?.backgroundColor = NSColor.textColor.cgColor.copy(alpha: 0.2)
                circle.translatesAutoresizingMaskIntoConstraints = false
                cell?.addSubview(circle)
                cell?.circleView = circle

                // MARK: - Create and Configure the Text Field
                let textField = NSTextField(labelWithString: "")
                textField.lineBreakMode = .byTruncatingTail
                textField.usesSingleLineMode = true
                textField.cell?.wraps = false
                textField.cell?.truncatesLastVisibleLine = true
                textField.translatesAutoresizingMaskIntoConstraints = false
                cell?.addSubview(textField)
                cell?.textField = textField
                
                // MARK: - Layout Constraints
                NSLayoutConstraint.activate([
                    // Circle constraints
                    circle.widthAnchor.constraint(equalToConstant: 5),
                    circle.heightAnchor.constraint(equalToConstant: 5),
                    circle.centerYAnchor.constraint(equalTo: cell!.centerYAnchor),
                    circle.leadingAnchor.constraint(equalTo: cell!.leadingAnchor, constant: 8),
                    
                    // Text field constraints
                    textField.leadingAnchor.constraint(equalTo: circle.trailingAnchor, constant: 7.1),
                    textField.trailingAnchor.constraint(equalTo: cell!.trailingAnchor, constant: -8),
                    textField.centerYAnchor.constraint(equalTo: cell!.centerYAnchor)
                ])

            }

            cell?.textField?.stringValue = filteredSuggestions[row].query
            cell?.circleView?.isHidden = filteredSuggestions[row].programs?.first == nil
            
            return cell
        }

    }
    
}

class CustomTableCellView: NSTableCellView {
    var circleView: NSView?
}

extension SuggestionSearchField.Coordinator: HoverDelegate {
    func didHover(row: Int) {
        guard row >= 0 && row < filteredSuggestions.count else { return }
        selectedIndex = row
        tableView?.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
    }
}


class HoverableTableRowView: NSTableRowView {
    var rowIndex: Int = -1
    weak var hoverDelegate: HoverDelegate?

    private var trackingArea: NSTrackingArea?

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let existing = trackingArea {
            removeTrackingArea(existing)
        }

        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeInActiveApp, .inVisibleRect]
        trackingArea = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        addTrackingArea(trackingArea!)
    }

    override func mouseEntered(with event: NSEvent) {
        hoverDelegate?.didHover(row: rowIndex)
    }

    override func mouseExited(with event: NSEvent) {
        hoverDelegate?.didHover(row: -1) // Optional: unselect on exit
    }
    
    override func drawSelection(in dirtyRect: NSRect) {
        if self.selectionHighlightStyle != .none {
            let selectionColor = NSColor.controlAccentColor.withAlphaComponent(0.8)

            // Add horizontal and vertical insets (padding)
            let insetRect = dirtyRect.insetBy(dx: 5, dy: 0)

            // Create rounded rectangle path
            let path = NSBezierPath(roundedRect: insetRect, xRadius: 5, yRadius: 5)

            selectionColor.setFill()
            path.fill()
        }
    }

}

protocol HoverDelegate: AnyObject {
    func didHover(row: Int)
}
#endif
