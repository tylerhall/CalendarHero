//
//  AppDelegate.swift
//  CalendarHero
//
//  Created by Tyler Hall on 2/17/21.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidBecomeActive(_ notification: Notification) {
        for window in NSApp.windows {
            (window as? Window)?.updateStyle()
        }
    }
    
    func applicationDidResignActive(_ notification: Notification) {
        for window in NSApp.windows {
            (window as? Window)?.updateStyle()
        }
    }
}
