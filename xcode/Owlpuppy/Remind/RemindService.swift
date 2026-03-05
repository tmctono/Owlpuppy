//
//  ApiRemindController.swift
//  Owlpuppy
//
//  Created by Manabu Tonosaki on 2026-03-05.
//


import Foundation
import EventKit

class RemindService: ServiceProtocol {
    // SINGLETON
    static let shared = RemindService()
    private init() {}
    
    private let eventStore = EKEventStore()
    private let owlpuppyListName = "Owlpuppy"
    
    func service(model: RemindModel) -> Bool {
        eventStore.requestFullAccessToReminders { [weak self] granted, error in
            guard let self = self else { return }
            if granted {
                self.createAndSaveReminder(model: model)
            } else {
                print("Error: Reminder access denied: \(String(describing: error))")
            }
        }
        return true
    }
    
    private func getOrCreateOwlpuppyList() -> EKCalendar? {
        let calendars = eventStore.calendars(for: .reminder)
        if let existingList = calendars.first(where: { $0.title == owlpuppyListName }) {
            return existingList
        }
        
        print("Owlpuppy: Create a new reminder list named Owlpuppy.")
        let newList = EKCalendar(for: .reminder, eventStore: eventStore)
        newList.title = owlpuppyListName
        
        if let defaultList = eventStore.defaultCalendarForNewReminders() {
            newList.source = defaultList.source
        } else {
            print("Error: Could not get a default calender for new reminders.")
            return nil
        }
        
        do {
            try eventStore.saveCalendar(newList, commit: true)
            return newList
        } catch {
            print("Error: at creating owlpuppy list: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func createAndSaveReminder(model: RemindModel) {
        model.items.forEach { item in
            let reminder = EKReminder(eventStore: eventStore)
            reminder.title = item.message
            reminder.notes = "hoge"
            
            guard let owlpuppyList = getOrCreateOwlpuppyList() else {
                print("Error: could no find Owlpuppy list.")
                return
            }
            reminder.calendar = owlpuppyList
            
            let alarm = EKAlarm(absoluteDate: item.isoDateTime)
            reminder.addAlarm(alarm)
            
            do {
                try eventStore.save(reminder, commit: true)
                print("Owlpuppy: will remind [\(item.message)] at \(item.isoDateTime)")
            } catch {
                print("Owlpuppy: Error \(error.localizedDescription)")
            }
        }
    }
}

