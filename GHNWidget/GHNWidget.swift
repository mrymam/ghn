import WidgetKit
import SwiftUI

struct PREntry: TimelineEntry {
    let date: Date
    let prs: [SharedPR]
}

struct GHNProvider: TimelineProvider {
    func placeholder(in context: Context) -> PREntry {
        PREntry(date: Date(), prs: [
            SharedPR(repo: "frontend", fullRepo: "org/frontend", number: 123,
                     title: "Fix login button", author: "alice",
                     url: "https://github.com/org/frontend/pull/123",
                     updatedAt: Date(), draft: false)
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (PREntry) -> Void) {
        let snapshot = SharedDataStore.read()
        completion(PREntry(date: Date(), prs: snapshot.prs))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PREntry>) -> Void) {
        let snapshot = SharedDataStore.read()
        let entry = PREntry(date: Date(), prs: snapshot.prs)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct GHNWidgetEntryView: View {
    var entry: PREntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        case .systemLarge:
            largeView
        default:
            mediumView
        }
    }

    private var smallView: some View {
        VStack(spacing: 4) {
            Image(systemName: entry.prs.isEmpty ? "bell" : "bell.badge.fill")
                .font(.system(size: 32))
                .foregroundColor(entry.prs.isEmpty ? .secondary : .orange)
            Text("\(entry.prs.count)")
                .font(.system(size: 28, weight: .bold))
            Text("Reviews")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "bell.badge.fill")
                    .foregroundColor(.orange)
                Text("Review Requests")
                    .font(.headline)
                Spacer()
                Text("\(entry.prs.count)")
                    .font(.title2.bold())
            }

            if entry.prs.isEmpty {
                Spacer()
                Text("No review requests")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                ForEach(entry.prs.prefix(3)) { pr in
                    Link(destination: URL(string: pr.url)!) {
                        HStack {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(pr.title)
                                    .font(.caption)
                                    .lineLimit(1)
                                Text("\(pr.repo) - \(pr.author)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                    }
                }
            }
        }
        .padding(4)
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var largeView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "bell.badge.fill")
                    .foregroundColor(.orange)
                Text("Review Requests")
                    .font(.headline)
                Spacer()
                Text("\(entry.prs.count)")
                    .font(.title2.bold())
            }

            Divider()

            if entry.prs.isEmpty {
                Spacer()
                Text("No review requests")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                ForEach(entry.prs.prefix(8)) { pr in
                    Link(destination: URL(string: pr.url)!) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(pr.title)
                                    .font(.caption)
                                    .lineLimit(1)
                                HStack(spacing: 4) {
                                    Text(pr.repo)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text(pr.author)
                                        .font(.caption2)
                                        .foregroundColor(.green)
                                }
                            }
                            Spacer()
                        }
                    }
                    Divider()
                }
            }

            Spacer(minLength: 0)
        }
        .padding(4)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

@main
struct GHNWidget: Widget {
    let kind = "com.mrymam.ghn.widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GHNProvider()) { entry in
            GHNWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("GHN Reviews")
        .description("Review requests on GitHub")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
