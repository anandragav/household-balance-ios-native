import Foundation

struct HouseholdEnvelope: Decodable {
  var user: MobileUser?
  var household: Household?
  var ok: Bool?
  var error: String?
}

struct MobileUser: Decodable {
  var id: String
  var email: String?
}

struct Household: Decodable, Identifiable {
  var id: String
  var name: String
  var parents: [Parent]
  var kids: [Kid]
  var events: [CalEvent]
  var assignments: [Assignment]
  var inbox: [InboxItem]
  var currentParentId: String
  var calendarConnections: [CalendarConnection]
}

struct Parent: Decodable, Identifiable {
  var id: String
  var userId: String?
  var name: String
  var short: String
  var role: String
}

struct Kid: Decodable, Identifiable {
  var id: String
  var name: String
  var age: Int
}

struct CalEvent: Decodable, Identifiable {
  var id: String
  var title: String
  var kind: String
  var start: String
  var end: String
  var kidId: String?
  var parentId: String?
  var location: String?
  var canceled: Bool?
}

struct Assignment: Decodable, Identifiable {
  var id: String
  var eventId: String
  var parentId: String
  var role: String
  var status: String
}

struct InboxItem: Decodable, Identifiable {
  var id: String
  var kind: String
  var title: String
  var body: String
  var assignmentId: String?
}

struct CalendarConnection: Decodable, Identifiable {
  var id: String
  var memberId: String
  var provider: String
  var lastSyncedAt: String?
}

extension Household {
  var me: Parent {
    parents.first(where: { $0.id == currentParentId })
      ?? parents.first
      ?? Parent(id: "me", userId: nil, name: "You", short: "You", role: "")
  }

  func events(on day: Date, kind: String? = nil) -> [CalEvent] {
    let cal = Calendar.current
    return events
      .filter { $0.canceled != true }
      .filter { kind == nil || $0.kind == kind }
      .filter { event in
        guard let date = ISO8601DateFormatter().date(from: event.start) else { return false }
        return cal.isDate(date, inSameDayAs: day)
      }
      .sorted { $0.start < $1.start }
  }
}
