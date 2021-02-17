//
//  Window.swift
//  CalendarHero
//
//  Created by Tyler Hall on 2/17/21.
//

import Cocoa

class Window: NSWindow {

    func updateStyle() {
        standardWindowButton(.miniaturizeButton)?.isHidden = true
        standardWindowButton(.zoomButton)?.isHidden = true
        standardWindowButton(.closeButton)?.isHidden = true

        collectionBehavior = .stationary

        if NSApp.isActive {
            styleMask = [.resizable, .fullSizeContentView, .titled]
            ignoresMouseEvents = false
            level = .normal
            isOpaque = true
            backgroundColor = .windowBackgroundColor
        } else {
            styleMask = [.borderless, .fullSizeContentView]
            ignoresMouseEvents = true
            orderBack(nil)
            level = NSWindow.Level.init(Int(CGWindowLevelForKey(CGWindowLevelKey.desktopWindow)))
            isOpaque = false
            backgroundColor = .clear
        }
    }

    override var tabbingMode: NSWindow.TabbingMode {
        get {
            return .disallowed
        }
        set {
            
        }
    }
}
