import EventKit
import Foundation
import Observation
import RPGTodoCore

/// カレンダーの予定1件（読み取り専用のコピー。元の予定は変更しない）。
struct CalendarEvent: Identifiable, Sendable {
    let key: String
    let title: String
    let start: Date
    let end: Date
    let isAllDay: Bool

    var id: String { key }
}

/// EventKit から今日・明日の予定を読み取る（要件 4.4）。読み取りのみで、予定の追加・変更・削除はしない。
@MainActor
@Observable
final class CalendarStore {
    private static let enabledKey = "calendar.enabled"

    private let store = EKEventStore()

    private(set) var status = EKEventStore.authorizationStatus(for: .event)
    private(set) var events: [CalendarEvent] = []

    /// 連携のオン・オフ（設定タブ・カレンダータブで切り替える。S-01・C-09）。
    private(set) var isEnabled = UserDefaults.standard.bool(forKey: CalendarStore.enabledKey)

    private func setEnabled(_ value: Bool) {
        isEnabled = value
        UserDefaults.standard.set(value, forKey: Self.enabledKey)
    }

    var hasAccess: Bool { status == .fullAccess }
    var isDenied: Bool { status == .denied || status == .restricted || status == .writeOnly }

    /// 連携をオンにする。まだ許可を聞いていなければ、ここで許可を求める（C-01）。
    func enable() async {
        setEnabled(true)
        if status == .notDetermined {
            _ = try? await store.requestFullAccessToEvents()
        }
        refresh()
    }

    /// 連携をオフにする。OS 側の許可は取り消さない（設定アプリで変更できる）。
    func disable() {
        setEnabled(false)
        events = []
    }

    /// 今日・明日の予定を読み直す（C-02）。
    func refresh(now: Date = .now) {
        status = EKEventStore.authorizationStatus(for: .event)
        guard isEnabled, hasAccess else {
            events = []
            return
        }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: now)
        guard let end = calendar.date(byAdding: .day, value: 2, to: start) else { return }

        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        events = store.events(matching: predicate)
            .sorted { $0.startDate < $1.startDate }
            .map { event in
                let identifier = event.eventIdentifier ?? event.calendarItemIdentifier
                return CalendarEvent(
                    key: CalendarEventKey.make(eventID: identifier, start: event.startDate),
                    title: event.title ?? "（タイトルなし）",
                    start: event.startDate,
                    end: event.endDate,
                    isAllDay: event.isAllDay
                )
            }
    }

    /// これから始まる（または進行中の）最初の予定。ホームのカードに出す（C-03）。
    func nextEvent(now: Date = .now) -> CalendarEvent? {
        events.first { $0.end > now && !$0.isAllDay } ?? events.first { $0.end > now }
    }

    /// 指定した日の予定。
    func events(on day: LocalDate) -> [CalendarEvent] {
        events.filter { LocalDate($0.start) == day }
    }
}
