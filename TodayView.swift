import SwiftUI

struct TodayView: View {
  @EnvironmentObject var session: SessionStore
  @State private var importing = false

  var body: some View {
    NavigationStack {
      List {
        if let household = session.household {
          Section("Kids today") {
            let kids = household.events(on: Date(), kind: "kid")
            if kids.isEmpty {
              Text("No kid events today.")
                .foregroundStyle(.secondary)
            }
            ForEach(kids) { event in
              EventRow(event: event)
            }
          }
          Section("Your work") {
            let work = household.events(on: Date(), kind: "work").filter {
              $0.parentId == household.currentParentId
            }
            if work.isEmpty {
              Text("Import this iPhone’s calendar to put work on the week.")
                .foregroundStyle(.secondary)
            }
            ForEach(work) { event in
              EventRow(event: event)
            }
            Button(importing ? "Reading calendar…" : "Import iPhone Calendar") {
              Task {
                importing = true
                do {
                  let blocks = try await CalendarImport.loadWorkBlocks()
                  await session.run(["type": "importWork", "blocks": blocks])
                } catch {
                  session.error = error.localizedDescription
                }
                importing = false
              }
            }
            .disabled(importing)
          }
          if let error = session.error {
            Text(error).foregroundStyle(.red)
          }
        }
      }
      .navigationTitle(session.household.map { "Hi, \($0.me.short)" } ?? "Today")
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Sign out") {
            Task { await session.signOut() }
          }
        }
      }
      .refreshable { await session.refresh() }
    }
  }
}

struct EventRow: View {
  let event: CalEvent
  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(event.title).font(.headline)
      Text(range(event.start, event.end))
        .font(.caption)
        .foregroundStyle(.secondary)
    }
  }
}

private func range(_ start: String, _ end: String) -> String {
  let iso = ISO8601DateFormatter()
  iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
  let iso2 = ISO8601DateFormatter()
  let formatter = DateFormatter()
  formatter.timeStyle = .short
  func parse(_ value: String) -> Date? {
    iso.date(from: value) ?? iso2.date(from: value)
  }
  guard let a = parse(start), let b = parse(end) else { return "" }
  return "\(formatter.string(from: a)) – \(formatter.string(from: b))"
}
