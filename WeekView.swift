import SwiftUI

struct WeekView: View {
  @EnvironmentObject var session: SessionStore

  var body: some View {
    NavigationStack {
      List {
        if let household = session.household {
          ForEach(0..<7, id: \.self) { offset in
            let day = Calendar.current.date(byAdding: .day, value: offset, to: Date()) ?? Date()
            Section(header: Text(day.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))) {
              let items = household.events(on: day)
              if items.isEmpty {
                Text("Clear").foregroundStyle(.secondary)
              }
              ForEach(items) { event in
                HStack {
                  Text(event.kind == "kid" ? "Kids" : "Work")
                    .font(.caption2)
                    .padding(4)
                    .background(event.kind == "kid" ? Color.orange.opacity(0.2) : Color.green.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                  EventRow(event: event)
                }
              }
            }
          }
        }
      }
      .navigationTitle(session.household?.name ?? "Week")
      .refreshable { await session.refresh() }
    }
  }
}
