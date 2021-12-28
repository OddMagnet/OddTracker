//
//  SimpleWidget.swift
//  OddTrackerWidgetExtension
//
//  Created by Michael Brünen on 28.12.21.
//

import WidgetKit
import SwiftUI
// import Intents

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

struct OddTrackerWidgetEntryView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            OddTrackerWidgetEntryView(
                entry: SimpleEntry(
                    date: Date(),
                    items: [Item.example, Item.example, Item.example, Item.example, Item.example]
                )
            )
            .previewContext(WidgetPreviewContext(family: .systemSmall))

            OddTrackerWidgetEntryView(
                entry: SimpleEntry(
                    date: Date(),
                    items: [Item.example, Item.example, Item.example, Item.example, Item.example]
                )
            )
            .previewContext(WidgetPreviewContext(family: .systemMedium))

            OddTrackerWidgetEntryView(
                entry: SimpleEntry(
                    date: Date(),
                    items: [Item.example, Item.example, Item.example, Item.example, Item.example]
                )
            )
            .previewContext(WidgetPreviewContext(family: .systemLarge))
        }
    }
}
