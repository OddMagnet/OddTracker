//
//  ItemRowView.swift
//  OddTracker
//
//  Created by Michael Brünen on 23.11.20.
//

import SwiftUI

struct ItemRowView: View {
    @ObservedObject var project: Project
    @ObservedObject var item: Item

    var icon: some View {
        if item.isCompleted {
            return Image(systemName: "checkmark.circle")
                .foregroundColor(project.projectColor)
        } else if item.priority == 3 {
            return Image(systemName: "exclamationmark.triangle")
                .foregroundColor(project.projectColor)
        } else {
            return Image(systemName: "checkmark.circle")
                .foregroundColor(.clear)    // clear image so items stay aligned
        }
    }

    var label: Text {
        if item.isCompleted {
            return Text("\(item.itemTitle), completed")
        } else if item.priority == 3 {
            return Text("\(item.itemTitle), high priority")
        } else {
            return Text(item.itemTitle)
        }
    }

    // initializer only for readability when using this View
    init(for item: Item, in project: Project) {
        _project = ObservedObject(wrappedValue: project)
        _item = ObservedObject(wrappedValue: item)
    }

    var body: some View {
        NavigationLink(destination: EditItemView(item: item)) {
            Label {
                Text(item.itemTitle)
            } icon: {
                icon
            }
            .accessibilityLabel(label)
        }
    }
}

struct ItemRowView_Previews: PreviewProvider {
    static var previews: some View {
        ItemRowView(for: Item.example, in: Project.example)
    }
}
