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
        let itemRequest = dataController.fetchRequestForTopItems(count: 1)
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

@main
struct OddTrackerWidget: Widget {
    let kind: String = "OddTrackerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            OddTrackerWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
    }
}

struct OddTrackerWidget_Previews: PreviewProvider {
    static var previews: some View {
        OddTrackerWidgetEntryView(entry: SimpleEntry(date: Date(), items: [Item.example]))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
