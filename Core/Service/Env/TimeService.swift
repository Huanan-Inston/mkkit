//
//  Month.swift
//
//  Created by MK on 2021/7/30.
//

import Foundation
import MKKit
import OpenCombine
import UIKit

// MARK: - Day

public struct Day {
    let calender: Calendar
    let year: Int
    let month: Int
    let day: Int

    fileprivate init(calender: Calendar, year: Int, month: Int, day: Int) {
        self.calender = calender
        self.year = year
        self.month = month
        self.day = day
    }

    public init(date: Date) {
        let calendar = date.calendar
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        self.init(calender: calendar, year: comps.year!, month: comps.month!, day: comps.day!)
    }
}

// MARK: Equatable

extension Day: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.calender.timeZone.identifier == rhs.calender.timeZone.identifier
            && lhs.year == rhs.year && lhs.month == rhs.month && lhs.day == rhs.day
    }
}

// MARK: - Hour

public struct Hour {
    let day: Day
    let hour: Int

    public init(day: Day, hour: Int) {
        self.day = day
        self.hour = hour
    }

    public init(date: Date) {
        let calendar = date.calendar
        let comps = calendar.dateComponents([.year, .month, .day, .hour], from: date)
        day = .init(calender: calendar, year: comps.year!, month: comps.month!, day: comps.day!)
        hour = comps.hour!
    }
}

// MARK: Equatable

extension Hour: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.hour == rhs.hour && lhs.day == rhs.day
    }
}

// MARK: - DayTime

public enum DayTime: Int {
    case morning = 5
    case afternoon = 12
    case evening = 17
}

// MARK: Equatable

extension DayTime: Equatable {}

public extension Hour {
    var dayTime: DayTime {
        if hour >= DayTime.evening.rawValue {
            return .evening
        } else if hour >= DayTime.afternoon.rawValue {
            return .afternoon
        } else if hour >= DayTime.morning.rawValue {
            return .morning
        } else {
            return .afternoon
        }
    }
}

// MARK: - TimeService

public class TimeService {
    private let hourSubject: CurrentValueSubject<Hour, Never>

    public lazy var hourPublisher = hourSubject.eraseToAnyPublisher()
    public lazy var dayPublisher = hourSubject.map(\.day).receiveOnMain().eraseToAnyPublisher()
    public lazy var dayTimePublisher = hourSubject.map(\.dayTime).receiveOnMain().eraseToAnyPublisher()

    private var LastHour: Int64 = 0
    private var lastMinute: Int64 = 0

    private var timer: SwiftTimer?
    private var dayChangeObs: AnyCancellable?

    public init() {
        let now = Date()
        hourSubject = .init(.init(date: now))

        let centerCombine = NotificationCenter.default.ocombine
        dayChangeObs = centerCombine.publisher(for: .NSCalendarDayChanged)
            .sink { [weak self] _ in
                self?.checkTime()
            }
    }
}

public extension TimeService {
    var hour: Hour {
        hourSubject.value
    }

    func startTimeCheck() {
        let interval = 3600
        let seconds = Int64(Date.timeIntervalSinceReferenceDate)
        var delay = interval - Int(seconds % Int64(interval))
        if delay == interval {
            delay = 0
        }

        timer = SwiftTimer(interval: .seconds(interval),
                           delay: .seconds(delay),
                           repeats: true,
                           handler: { [weak self] _ in
                               self?.checkTime()
                           })
        timer?.start()
    }

    func stopTimeCheck() {
        timer = nil
    }

    private func checkTime() {
        let hour = Hour(date: .init())
        if hour != hourSubject.value {
            hourSubject.value = hour
        }
    }
}