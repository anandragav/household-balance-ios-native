import EventKit
import Foundation

enum CalendarImport {
  static func loadWorkBlocks() async throws -> [[String: Any]] {
    let store = EKEventStore()
    if #available(iOS 17.0, *) {
      let ok = try await store.requestFullAccessToEvents()
      guard ok else { throw APIError.message("Calendar access was declined.") }
    } else {
      let ok = try await store.requestAccess(to: .event)
      guard ok else { throw APIError.message("Calendar access was declined.") }
    }

    let start = Calendar.current.startOfDay(for: Date())
    let end = Calendar.current.date(byAdding: .day, value: 14, to: start) ?? start
    let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
    let events = store.events(matching: predicate)
    let iso = ISO8601DateFormatter()
    iso.formatOptions = [.withInternetDateTime]

    return events
      .filter { !$0.isAllDay }
      .filter { $0.status != .canceled }
      .map { event in
      [
        "id": "ek-\(event.eventIdentifier ?? UUID().uuidString)",
        "title": event.title ?? "Busy",
        "start": iso.string(from: event.startDate),
        "end": iso.string(from: event.endDate),
        "protected": true,
      ] as [String: Any]
    }
  }
}
