import AppKit
import SwiftUI

@main
@MainActor
struct HumApp {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private let recognizer = AudioRecognizer()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "music.note", accessibilityDescription: "Hum")
            button.action = #selector(togglePopover)
            button.target = self
        }

        popover = NSPopover()
        popover.behavior = .applicationDefined
        let hostingController = NSHostingController(
            rootView: MenuBarView(recognizer: recognizer)
        )
        hostingController.sizingOptions = .preferredContentSize
        popover.contentViewController = hostingController

        // Close popover when user clicks outside, but not while listening
        NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self else { return }
            MainActor.assumeIsolated {
                guard self.popover.isShown else { return }
                if self.recognizer.state != .listening {
                    self.popover.performClose(nil)
                }
            }
        }
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}
