//
//  ItemRowView.swift
//  OddTracker
//
//  Created by Michael Brünen on 23.11.20.
//

import SwiftUI

/// A View that represents a row for an Item
struct ItemRowView: View {
    @StateObject var viewModel: ViewModel
    @ObservedObject var item: Item

    // initializer only for readability when using this View
    init(for item: Item, in project: Project) {
        let viewModel = ViewModel(for: item, in: project)
        _viewModel = StateObject(wrappedValue: viewModel)

        self.item = item
    }

    var body: some View {
        NavigationLink(destination: EditItemView(item: item)) {
            Label {
                Text(viewModel.itemTitle)
            } icon: {
                Image(systemName: viewModel.icon)
                    .foregroundColor(viewModel.color.map { Color($0) } ?? .clear)
            }
            .accessibilityLabel(viewModel.label)
        }
    }
}

struct ItemRowView_Previews: PreviewProvider {
    static var previews: some View {
        ItemRowView(for: Item.example, in: Project.example)
    }
}
