//
//  OddTrackerWidget.swift
//  OddTrackerWidget
//
//  Created by Michael Brünen on 15.06.21.
//

import WidgetKit
import SwiftUI
import Intents

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), items: [Item.example])
    }

    /// Load the top items
    /// - Returns: An array of the top items
    func loadItems() -> [Item] {
        let dataController = DataController()
        let itemRequest = dataController.fetchRequestForTopItems(count: 5)
        return dataController.results(for: itemRequest)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        let entry = SimpleEntry(date: Date(), items: loadItems())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let entry = SimpleEntry(date: Date(), items: loadItems())
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let items: [Item]
}

// MARK: - WidgetBundle
@main
struct OddTrackerWidgets: WidgetBundle {
    var body: some Widget {
        SimpleOddTrackerWidget()
        ComplexOddTrackerWidget()
    }
}

// MARK: - Simple Widget
struct OddTrackerWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            Text("Up next…")
                .font(.title)

            if let item = entry.items.first {
                Text(item.itemTitle)
            } else {
                Text("Nothing!")
            }
        }
    }
}

struct SimpleOddTrackerWidget: Widget {
    let kind: String = "SimpleOddTrackerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            OddTrackerWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Up Next…")
        .description("Your #1 top-priority item.")
    }
}

// MARK: - Multiple Items Widget
struct OddTrackerWidgetMultipleEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        Text("Hello, world!")
    }
}

struct ComplexOddTrackerWidget: Widget {
    let kind: String = "ComplexOddTrackerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            OddTrackerWidgetMultipleEntryView(entry: entry)
        }
        .configurationDisplayName("Up next…")
        .description("Your most important items.")
    }
}

struct OddTrackerWidget_Previews: PreviewProvider {
    static var previews: some View {
        OddTrackerWidgetEntryView(entry: SimpleEntry(date: Date(), items: [Item.example]))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
