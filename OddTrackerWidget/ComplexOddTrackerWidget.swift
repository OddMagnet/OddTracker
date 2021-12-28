//
//  ComplexOddTrackerWidget.swift
//  OddTrackerWidgetExtension
//
//  Created by Michael Brünen on 28.12.21.
//

import WidgetKit
import SwiftUI
// import Intents

struct OddTrackerWidgetMultipleEntryView: View {
    var entry: Provider.Entry

    @Environment(\.widgetFamily) var widgetFamily
    @Environment(\.sizeCategory) var sizeCategory
    var items: ArraySlice<Item> {
        let itemCount: Int

        switch widgetFamily {
            case .systemSmall:
                itemCount = 1
            case .systemMedium:
                if sizeCategory < .extraLarge {
                    itemCount = 3
                } else {
                    itemCount = 2
                }
            case .systemLarge:
                if sizeCategory < .extraExtraLarge {
                    itemCount = 5
                } else {
                    itemCount = 4
                }
            default:
                // For future widgetFamilies
                itemCount = 2
        }

        return entry.items.prefix(itemCount)
    }

    var body: some View {
        VStack(spacing: 5) {
            ForEach(items) { item in
                HStack {
                    Color(item.project?.color ?? "Light Blue")
                        .frame(width: 5)
                        .clipShape(Capsule())

                    VStack(alignment: .leading) {
                        Text(item.itemTitle)
                            .font(.headline)
                            .layoutPriority(1)

                        if let projectTitle = item.project?.projectTitle {
                            Text(projectTitle)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()
                }
            }
        }
        .padding(20)
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

struct OddTrackerWidgetMultipleEntryView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            OddTrackerWidgetMultipleEntryView(
                entry: SimpleEntry(
                    date: Date(),
                    items: [Item.example, Item.example, Item.example, Item.example, Item.example]
                )
            )
                .previewContext(WidgetPreviewContext(family: .systemSmall))

            OddTrackerWidgetMultipleEntryView(
                entry: SimpleEntry(
                    date: Date(),
                    items: [Item.example, Item.example, Item.example, Item.example, Item.example]
                )
            )
                .previewContext(WidgetPreviewContext(family: .systemMedium))

            OddTrackerWidgetMultipleEntryView(
                entry: SimpleEntry(
                    date: Date(),
                    items: [Item.example, Item.example, Item.example, Item.example, Item.example]
                )
            )
                .previewContext(WidgetPreviewContext(family: .systemLarge))
        }
    }
}
