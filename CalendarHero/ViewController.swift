//
//  ViewController.swift
//  CalendarHero
//
//  Created by Tyler Hall on 2/17/21.
//

import Cocoa
import EventKit

class ViewController: NSViewController {

    @IBOutlet weak var weekStackView: NSStackView!

    let store = EKEventStore()

    let startHour = 0
    let endHour = 23

    var start: Date {
        return Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
    }

    var end: Date {
        return Date(timeInterval: 86400 * 7, since: start)
    }

    var refreshTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()

        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true, block: { [weak self] (timer) in
            self?.loadCalendars()
        })
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
            guard granted else { return }
            self?.loadCalendars()
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
            
            let day = Calendar.current.component(.weekday, from: Date())
            let todayStackView = self.weekStackView.arrangedSubviews[day] as! DayStackView
            todayStackView.backgroundColor = .lightGray
            
            for view in todayStackView.arrangedSubviews {
                if let view = view as? HourStackView {
                    view.backgroundColor = nil
                }
            }
            let hour = Calendar.current.component(.hour, from: Date())
            let hourView = todayStackView.arrangedSubviews[hour] as! HourStackView
            hourView.layer?.borderWidth = 2
            hourView.layer?.borderColor = NSColor.red.cgColor
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
