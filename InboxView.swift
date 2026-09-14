import SwiftUI

struct InboxView: View {
  @EnvironmentObject var session: SessionStore

  var body: some View {
    NavigationStack {
      List {
        if let household = session.household {
          if household.inbox.isEmpty {
            Text("Inbox is clear.")
              .foregroundStyle(.secondary)
          }
          ForEach(household.inbox) { item in
            VStack(alignment: .leading, spacing: 8) {
              Text(item.title).font(.headline)
              Text(item.body).font(.subheadline).foregroundStyle(.secondary)
              if let assignmentId = item.assignmentId, item.kind == "proposal" {
                HStack {
                  Button("Accept") {
                    Task { await session.run(["type": "accept", "assignmentId": assignmentId]) }
                  }
                  Button("Decline", role: .destructive) {
                    Task { await session.run(["type": "decline", "assignmentId": assignmentId]) }
                  }
                }
              }
            }
            .padding(.vertical, 4)
          }
        }
      }
      .navigationTitle("Inbox")
      .refreshable { await session.refresh() }
    }
  }
}
