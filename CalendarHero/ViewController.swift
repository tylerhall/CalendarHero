//
//  ViewController.swift
//  CalendarHero
//
//  Created by Tyler Hall on 2/17/21.
//

import Cocoa
import EventKit

class ViewController: NSViewController {

    @IBOutlet weak var nextEventCountdownTextField: NSTextField!
    @IBOutlet weak var weekStackView: NSStackView!

    let store = EKEventStore()

    let startHour = 0
    let endHour = 23
    
    // This is just a wrapper around the current date,
    // so I can test other dates during development.
    var theDate: Date {
        return Date() // Date(timeIntervalSinceNow: 3600 * 6)
    }

    var start: Date {
        return Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: theDate))!
    }

    var end: Date {
        return Date(timeInterval: 86400 * 7, since: start)
    }

    var refreshTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        nextEventCountdownTextField.stringValue = ""
        
        setup()

        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true, block: { [weak self] (timer) in
            self?.loadCalendars()
        })
    }

    @objc func calendarDidChange(_ notification: Notification) {
        loadCalendars()
    }
    
    func setup() {
        for i in 0..<7 {
            let dayStackView = DayStackView(views: [])
            dayStackView.orientation = .vertical
            dayStackView.distribution = .fillEqually
            dayStackView.alignment = .leading

            weekStackView.insertArrangedSubview(dayStackView, at: i)

            var pos = 0
            for _ in startHour..<endHour {
                let hourStackView = HourStackView(views: [])
                hourStackView.orientation = .horizontal
                hourStackView.distribution = .fillProportionally
                hourStackView.edgeInsets = NSEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
                dayStackView.insertArrangedSubview(hourStackView, at: pos)
                pos += 1
            }
        }

        store.requestAccess(to: .event) { [weak self] granted, error in
            guard let self = self else { return }
            guard granted else { return }
            self.loadCalendars()
            NotificationCenter.default.addObserver(self, selector: #selector(self.calendarDidChange(_:)), name: .EKEventStoreChanged, object: self.store)
        }
    }
    
    func loadCalendars() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            for dayStackView in self.weekStackView.arrangedSubviews as! [NSStackView] {
                for hourStackView in dayStackView.arrangedSubviews as! [NSStackView] {
                    for view in hourStackView.arrangedSubviews {
                        hourStackView.removeArrangedSubview(view)
                        view.removeFromSuperview()
                    }
                }
            }

            let df = DateFormatter()
            df.dateStyle = .none
            df.timeStyle = .short

            let predicate = self.store.predicateForEvents(withStart: self.start, end: self.end, calendars: nil)
            let events = self.store.events(matching: predicate)
            for e in events {
                let str = df.string(from: e.startDate) + " " + e.title
                let hourStackView = self.stackViewForEvent(e)
                let eventBubbleView = EventBubbleView(wrappingLabelWithString: str)
                eventBubbleView.backgroundColor = e.calendar.color
                eventBubbleView.textColor = .white
                hourStackView?.addArrangedSubview(eventBubbleView)
            }

            let day = Calendar.current.component(.weekday, from: self.theDate) - 1
            let todayStackView = self.weekStackView.arrangedSubviews[day] as! DayStackView
            todayStackView.backgroundColor = .lightGray
            
            for view in todayStackView.arrangedSubviews {
                if let view = view as? HourStackView {
                    view.layer?.borderWidth = 0
                    view.layer?.borderColor = nil
                }
            }

            let hour = Calendar.current.component(.hour, from: self.theDate)
            if hour < todayStackView.arrangedSubviews.count {
                let hourView = todayStackView.arrangedSubviews[hour] as! HourStackView
                hourView.layer?.borderWidth = 2
                hourView.layer?.borderColor = NSColor.red.cgColor
            }

            self.calculateNextEvent()
        }
    }

    func stackViewForEvent(_ event: EKEvent) -> NSStackView? {
        guard !event.isAllDay else { return nil }
        
        var day = 0
        while event.startDate > Date(timeInterval: Double((day + 1) * 86400), since: start) {
            day += 1
        }

        guard (0 <= day) && (day <= 7) else { return nil }

        let hour = Calendar.current.component(.hour, from: event.startDate)
        guard (startHour <= hour) && (hour <= endHour) else { return nil }
        
        let dayStackView = weekStackView.arrangedSubviews[day] as! NSStackView
        let hourStackView = dayStackView.arrangedSubviews[hour] as! NSStackView

        return hourStackView
    }

    func calculateNextEvent() {
        let offsetStart = Date(timeIntervalSinceNow: 60 * 5 * -1)
        let aDayFromNow = Date(timeIntervalSinceNow: 86400 * 3) // Just a random future date.
        let predicate = self.store.predicateForEvents(withStart: offsetStart, end: aDayFromNow, calendars: nil)
        let events = self.store.events(matching: predicate)
        
        // I couldn't find where it's guaranteed events come back sorted,
        // so let's do that just to be safe.
        let sortedEvents = events.sorted { (a, b) -> Bool in
            return a.startDate < b.startDate
        }

        if let nextEvent = sortedEvents.first(where: { (event) -> Bool in
            return !event.isAllDay
        }) {
            let df = RelativeDateTimeFormatter()
            nextEventCountdownTextField.stringValue = "Next event " + df.localizedString(fromTimeInterval: nextEvent.startDate.timeIntervalSinceNow)
        } else {
            nextEventCountdownTextField.stringValue = ""
        }
    }
}

class HourStackView: DayStackView {
    
}

class DayStackView: NSStackView {
    
    var backgroundColor: NSColor?

    override func draw(_ dirtyRect: NSRect) {
        if let backgroundColor = backgroundColor {
            let path = NSBezierPath(roundedRect: bounds, xRadius: 8, yRadius: 8)
            backgroundColor.setFill()
            path.fill()
        }
        super.draw(dirtyRect)
    }
}

class EventBubbleView: NSTextField {
    
    override var intrinsicContentSize: NSSize {
        let size = super.intrinsicContentSize
        return NSSize(width: size.width + 32, height: size.height + 16)
    }

    override func draw(_ dirtyRect: NSRect) {
        let path = NSBezierPath(roundedRect: bounds, xRadius: 8, yRadius: 8)
        backgroundColor?.setFill()
        path.fill()
        super.draw(dirtyRect)
    }
}
