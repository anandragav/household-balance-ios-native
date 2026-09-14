import SwiftUI

struct RootView: View {
  @EnvironmentObject var session: SessionStore

  var body: some View {
    Group {
      switch session.status {
      case .booting:
        BootView()
      case .signedOut:
        SignInView()
      case .empty:
        EmptyHouseholdView()
      case .ready:
        AppTabs()
      }
    }
    .tint(Color(red: 0.25, green: 0.42, blue: 0.35))
    .task { await session.boot() }
  }
}

struct BootView: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("HOUSEHOLD BALANCE")
        .font(.caption)
        .foregroundStyle(.secondary)
      Text("Two careers. One week.")
        .font(.largeTitle.weight(.semibold))
      Text("Opening the household")
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .padding(28)
    .background(Color(red: 0.96, green: 0.94, blue: 0.90))
  }
}

struct AppTabs: View {
  var body: some View {
    TabView {
      TodayView()
        .tabItem { Label("Today", systemImage: "sun.max") }
      WeekView()
        .tabItem { Label("Week", systemImage: "calendar") }
      InboxView()
        .tabItem { Label("Inbox", systemImage: "tray") }
    }
  }
}

struct EmptyHouseholdView: View {
  @EnvironmentObject var session: SessionStore
  @State private var name = ""
  @State private var household = "Our household"
  @State private var kid = ""

  var body: some View {
    NavigationStack {
      Form {
        Section("Household") {
          TextField("Your name", text: $name)
          TextField("Household name", text: $household)
          TextField("First child", text: $kid)
        }
        Button("Create household") {
          Task {
            await session.run([
              "type": "createHousehold",
              "householdName": household,
              "displayName": name,
              "kids": [["name": kid, "age": 5]],
              "sampleWeek": true,
            ])
          }
        }
        .disabled(name.isEmpty || kid.isEmpty)
      }
      .navigationTitle("Start")
    }
  }
}
