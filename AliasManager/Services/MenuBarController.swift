import AppKit
import SwiftUI

/// Manages the menu bar status item.
/// Shows top aliases with copy / run options.
@MainActor
final class MenuBarController: ObservableObject {

    private var statusItem: NSStatusItem?
    private weak var viewModel: AliasViewModel?

    // MARK: - Setup

    func setup(viewModel: AliasViewModel) {
        self.viewModel = viewModel

        guard AppSettings.shared.menuBarEnabled else {
            remove()
            return
        }

        if statusItem == nil {
            statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        }
        configureButton()
        buildMenu()
    }

    func remove() {
        if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
            statusItem = nil
        }
    }

    func rebuild() {
        guard AppSettings.shared.menuBarEnabled, statusItem != nil else { return }
        buildMenu()
    }

    // MARK: - Button

    private func configureButton() {
        guard let button = statusItem?.button else { return }
        button.image = NSImage(systemSymbolName: "terminal.fill", accessibilityDescription: "AliasManager")
        button.image?.isTemplate = true
        button.toolTip = "AliasManager"
    }

    // MARK: - Menu

    private func buildMenu() {
        let menu = NSMenu()

        // Header
        let headerItem = NSMenuItem(title: "AliasManager", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)
        menu.addItem(.separator())

        guard let vm = viewModel else { return }

        // Top aliases section
        let top = vm.topAliases(limit: 10)

        if top.isEmpty {
            // Show first 10 aliases if none used yet
            let shown = vm.aliases.prefix(10)
            if shown.isEmpty {
                let empty = NSMenuItem(title: "No aliases yet", action: nil, keyEquivalent: "")
                empty.isEnabled = false
                menu.addItem(empty)
            } else {
                for alias in shown {
                    menu.addItem(makeAliasItem(alias))
                }
            }
        } else {
            let topHeader = NSMenuItem(title: "MOST USED", action: nil, keyEquivalent: "")
            topHeader.isEnabled = false
            menu.addItem(topHeader)

            for alias in top {
                menu.addItem(makeAliasItem(alias))
            }
        }

        menu.addItem(.separator())

        // Quick Search
        let searchItem = NSMenuItem(title: "Quick Search  ⌘K", action: #selector(openQuickSearch), keyEquivalent: "")
        searchItem.target = self
        menu.addItem(searchItem)

        menu.addItem(.separator())

        // Open main window
        let openItem = NSMenuItem(title: "Open AliasManager", action: #selector(openMainWindow), keyEquivalent: "")
        openItem.target = self
        menu.addItem(openItem)

        menu.addItem(.separator())

        // Quit
        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    // MARK: - Alias Menu Item

    private func makeAliasItem(_ alias: AliasItem) -> NSMenuItem {
        let title = alias.usageCount > 0
            ? "\(alias.name)  (\(alias.usageCount)×)"
            : alias.name
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")

        // Disabled styling
        if !alias.isEnabled {
            item.isEnabled = false
        }

        // Submenu: copy / open detail
        let sub = NSMenu()

        let copyCmd = NSMenuItem(title: "Copy Command", action: #selector(copyCommandAction(_:)), keyEquivalent: "")
        copyCmd.target = self
        copyCmd.representedObject = alias.command
        sub.addItem(copyCmd)

        let copyAlias = NSMenuItem(title: "Copy Alias Line", action: #selector(copyAliasLineAction(_:)), keyEquivalent: "")
        copyAlias.target = self
        copyAlias.representedObject = alias.preview
        sub.addItem(copyAlias)

        if !alias.command.isEmpty {
            sub.addItem(.separator())
            let cmdDisplay = alias.command.count > 40
                ? String(alias.command.prefix(40)) + "…"
                : alias.command
            let preview = NSMenuItem(title: cmdDisplay, action: nil, keyEquivalent: "")
            preview.isEnabled = false
            sub.addItem(preview)
        }

        item.submenu = sub
        return item
    }

    // MARK: - Actions

    @objc private func copyCommandAction(_ sender: NSMenuItem) {
        guard let cmd = sender.representedObject as? String else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(cmd, forType: .string)
    }

    @objc private func copyAliasLineAction(_ sender: NSMenuItem) {
        guard let line = sender.representedObject as? String else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(line, forType: .string)
    }

    @objc private func openQuickSearch() {
        NotificationCenter.default.post(name: .showQuickSearch, object: nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        for window in NSApp.windows {
            if !window.isKind(of: NSPanel.self) {
                window.makeKeyAndOrderFront(nil)
                return
            }
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let showQuickSearch   = Notification.Name("showQuickSearch")
    static let menuBarNeedsRebuild = Notification.Name("menuBarNeedsRebuild")
}
